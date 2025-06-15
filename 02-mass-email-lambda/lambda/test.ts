import { SendEmailCommand, SESv2Client } from '@aws-sdk/client-sesv2'
import chalk from 'chalk';
import * as dotenv from 'dotenv'
dotenv.config();



const {
    REGION,
    ACCESS_KEY,
    SECRET_KEY,
    S3_BUCKET,
    CSV_FILE,
    FROM_EMAIL,
    SES_ENDPOINT,
    DEBUG_MODE
} = process.env

const isDebug = DEBUG_MODE === 'true'

// Logging helpers
const log = {
    info: (msg: string) => console.log(chalk.cyan('[INFO]'), msg),
    debug: (msg: string) => isDebug && console.log(chalk.yellow('[DEBUG]'), msg),
    success: (msg: string) => console.log(chalk.green('[SUCCESS]'), msg),
    error: (msg: string, err?: any) => {
        console.error(chalk.red('[ERROR]'), msg)
        if (isDebug && err) console.error(chalk.gray(err))
    }
}

const ses = new SESv2Client({
    region: REGION,
    endpoint: SES_ENDPOINT || undefined,
    credentials: { accessKeyId: ACCESS_KEY!, secretAccessKey: SECRET_KEY! },
})

const testSend = async () => {
    try {
        await ses.send(new SendEmailCommand({
            FromEmailAddress: FROM_EMAIL!,
            Destination: { ToAddresses: [FROM_EMAIL!] },  // send to self first
            Content: {
                Simple: {
                    Subject: { Data: 'Test Email' },
                    Body: { Text: { Data: 'Hello from SES test.' } },
                },
            },
        }))
        console.log('Test email sent successfully')
    } catch (error) {
        console.error('Test send failed:', error)
    }
}
testSend()
