"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ses = exports.s3 = void 0;
const client_s3_1 = require("@aws-sdk/client-s3");
const client_sesv2_1 = require("@aws-sdk/client-sesv2");
const { REGION, ACCESS_KEY, SECRET_KEY, SES_ENDPOINT } = process.env;
exports.s3 = new client_s3_1.S3Client({
    region: REGION,
    credentials: { accessKeyId: ACCESS_KEY, secretAccessKey: SECRET_KEY },
    forcePathStyle: true,
});
exports.ses = new client_sesv2_1.SESv2Client({
    region: REGION,
    endpoint: SES_ENDPOINT || undefined,
    credentials: { accessKeyId: ACCESS_KEY, secretAccessKey: SECRET_KEY },
});
