import { S3Client } from '@aws-sdk/client-s3'
import { SESv2Client } from '@aws-sdk/client-sesv2'

const {
    REGION,
    ACCESS_KEY,
    SECRET_KEY,
    SES_ENDPOINT
} = process.env

export const s3 = new S3Client({
    region: REGION,
    credentials: { accessKeyId: ACCESS_KEY!, secretAccessKey: SECRET_KEY! },
    forcePathStyle: true,
})

export const ses = new SESv2Client({
    region: REGION,
    endpoint: SES_ENDPOINT || undefined,
    credentials: { accessKeyId: ACCESS_KEY!, secretAccessKey: SECRET_KEY! },
})
