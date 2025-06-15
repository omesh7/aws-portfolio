"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getEmails = void 0;
const client_s3_1 = require("@aws-sdk/client-s3");
const sync_1 = require("csv-parse/sync");
const stream_1 = require("./stream");
const awsClients_1 = require("./awsClients");
const logger_1 = require("./logger");
const { S3_BUCKET, CSV_FILE } = process.env;
const getEmails = async () => {
    try {
        logger_1.log.info(`Fetching CSV from S3: ${S3_BUCKET}/${CSV_FILE}`);
        const data = await awsClients_1.s3.send(new client_s3_1.GetObjectCommand({
            Bucket: S3_BUCKET,
            Key: CSV_FILE
        }));
        const csvText = await (0, stream_1.streamToString)(data.Body);
        const records = (0, sync_1.parse)(csvText, { columns: true });
        return records.map((r) => r.email).filter(Boolean);
    }
    catch (err) {
        logger_1.log.error('Failed to get emails from S3', err);
        return [];
    }
};
exports.getEmails = getEmails;
