import dotenv from 'dotenv'
import { createRequire } from "module";

import { Context, S3Event, APIGatewayProxyEvent } from 'aws-lambda';
import { SendEmailCommand } from '@aws-sdk/client-sesv2'
import { log } from './utils/logger'
import { getEmails } from './utils/emailUtils'
import { ses } from './utils/awsClients'

dotenv.config()

const { FROM_EMAIL } = process.env

export const handler = async (event: S3Event, context: Context) => {
    log.info('🚀 Starting mass email sender Lambda...')
    const emails = await getEmails()

    if (emails.length === 0) {
        log.info('📭 No emails to send.')
        return
    }

    for (const email of emails) {
        const cmd = new SendEmailCommand({
            FromEmailAddress: FROM_EMAIL!,
            Destination: { ToAddresses: [email] },
            Content: {
                Simple: {
                    Subject: { Data: 'Mass Mail Test' },
                    Body: { Text: { Data: 'This is a test email sent via Lambda!' } }
                }
            }
        })

        try {
            await ses.send(cmd)
            log.success(`✅ Email sent to: ${email}`)
        } catch (err) {
            log.error(`❌ Failed to send to ${email}`, err)
        }
    }

    log.info('📤 All emails processed.')
}
