import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';
import { githubAPI } from '@/lib/github-api';

function validateToken(token: string, ip: string): boolean {
  try {
    const decoded = JSON.parse(Buffer.from(token, 'base64').toString());
    const now = Date.now();
    const tokenAge = now - decoded.timestamp;
    const maxAge = 24 * 60 * 60 * 1000; // 24 hours
    
    return (
      decoded.authenticated === true &&
      decoded.ip === ip &&
      tokenAge < maxAge
    );
  } catch {
    return false;
  }
}

async function getClientIP(request: NextRequest): Promise<string> {
  const headersList = await headers();
  return (
    headersList.get('x-forwarded-for')?.split(',')[0] ||
    headersList.get('x-real-ip') ||
    'unknown'
  );
}

export async function POST(request: NextRequest) {
  const ip = await getClientIP(request);
  
  try {
    const { projectId, action, token } = await request.json();
    
    // Validate required fields
    if (!projectId || !action || !token) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }
    
    // Validate token
    if (!validateToken(token, ip)) {
      return NextResponse.json(
        { error: 'Invalid or expired token' },
        { status: 401 }
      );
    }
    
    // Validate action
    if (!['deploy', 'destroy'].includes(action)) {
      return NextResponse.json(
        { error: 'Invalid action' },
        { status: 400 }
      );
    }
    
    // Trigger deployment
    const success = await githubAPI.triggerDeployment(projectId, action);
    
    if (!success) {
      return NextResponse.json(
        { error: 'Failed to trigger deployment' },
        { status: 500 }
      );
    }
    
    return NextResponse.json({ success: true });
    
  } catch (error) {
    return NextResponse.json(
      { error: 'Invalid request' },
      { status: 400 }
    );
  }
}