import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';

// Rate limiting store (in production, use Redis)
const attempts = new Map<string, { count: number; lastAttempt: number }>();
const RATE_LIMIT_WINDOW = 15 * 60 * 1000; // 15 minutes
const MAX_ATTEMPTS = 5;

async function getClientIP(request: NextRequest): Promise<string> {
  const headersList = await headers();
  return (
    headersList.get('x-forwarded-for')?.split(',')[0] ||
    headersList.get('x-real-ip') ||
    'unknown'
  );
}

function isRateLimited(ip: string): boolean {
  const now = Date.now();
  const userAttempts = attempts.get(ip);
  
  if (!userAttempts) return false;
  
  // Reset if window expired
  if (now - userAttempts.lastAttempt > RATE_LIMIT_WINDOW) {
    attempts.delete(ip);
    return false;
  }
  
  return userAttempts.count >= MAX_ATTEMPTS;
}

function recordAttempt(ip: string, success: boolean) {
  const now = Date.now();
  const userAttempts = attempts.get(ip) || { count: 0, lastAttempt: now };
  
  if (success) {
    attempts.delete(ip);
  } else {
    userAttempts.count++;
    userAttempts.lastAttempt = now;
    attempts.set(ip, userAttempts);
  }
}

export async function POST(request: NextRequest) {
  const ip = await getClientIP(request);
  
  // Check rate limiting
  if (isRateLimited(ip)) {
    return NextResponse.json(
      { error: 'Too many attempts. Try again in 15 minutes.' },
      { status: 429 }
    );
  }
  
  try {
    const { password } = await request.json();
    
    if (!password) {
      recordAttempt(ip, false);
      return NextResponse.json(
        { error: 'Password required' },
        { status: 400 }
      );
    }
    
    const adminPassword = process.env.ADMIN_PASSWORD;
    if (!adminPassword) {
      return NextResponse.json(
        { error: 'Server configuration error' },
        { status: 500 }
      );
    }
    
    const isValid = password === adminPassword;
    recordAttempt(ip, isValid);
    
    if (!isValid) {
      return NextResponse.json(
        { error: 'Invalid password' },
        { status: 401 }
      );
    }
    
    // Generate session token (simple JWT alternative)
    const token = Buffer.from(
      JSON.stringify({
        authenticated: true,
        timestamp: Date.now(),
        ip: ip
      })
    ).toString('base64');
    
    return NextResponse.json({ token });
    
  } catch (error) {
    recordAttempt(ip, false);
    return NextResponse.json(
      { error: 'Invalid request' },
      { status: 400 }
    );
  }
}