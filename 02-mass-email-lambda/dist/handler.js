"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handler = void 0;
const dotenv_1 = __importDefault(require("dotenv"));
const client_sesv2_1 = require("@aws-sdk/client-sesv2");
const logger_1 = require("./utils/logger");
const emailUtils_1 = require("./utils/emailUtils");
const awsClients_1 = require("./utils/awsClients");
dotenv_1.default.config();
const { FROM_EMAIL } = process.env;
const handler = async () => {
    logger_1.log.info('🚀 Starting mass email sender Lambda...');
    const emails = await (0, emailUtils_1.getEmails)();
    if (emails.length === 0) {
        logger_1.log.info('📭 No emails to send.');
        return;
    }
    for (const email of emails) {
        const cmd = new client_sesv2_1.SendEmailCommand({
            FromEmailAddress: FROM_EMAIL,
            Destination: { ToAddresses: [email] },
            Content: {
                Simple: {
                    Subject: { Data: 'Mass Mail Test' },
                    Body: { Text: { Data: 'This is a test email sent via Lambda!' } }
                }
            }
        });
        try {
            await awsClients_1.ses.send(cmd);
            logger_1.log.success(`✅ Email sent to: ${email}`);
        }
        catch (err) {
            logger_1.log.error(`❌ Failed to send to ${email}`, err);
        }
    }
    logger_1.log.info('📤 All emails processed.');
};
exports.handler = handler;
