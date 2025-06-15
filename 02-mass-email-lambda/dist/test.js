"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const client_sesv2_1 = require("@aws-sdk/client-sesv2");
const chalk_1 = __importDefault(require("chalk"));
const dotenv = __importStar(require("dotenv"));
dotenv.config();
const { REGION, ACCESS_KEY, SECRET_KEY, S3_BUCKET, CSV_FILE, FROM_EMAIL, SES_ENDPOINT, DEBUG_MODE } = process.env;
const isDebug = DEBUG_MODE === 'true';
// Logging helpers
const log = {
    info: (msg) => console.log(chalk_1.default.cyan('[INFO]'), msg),
    debug: (msg) => isDebug && console.log(chalk_1.default.yellow('[DEBUG]'), msg),
    success: (msg) => console.log(chalk_1.default.green('[SUCCESS]'), msg),
    error: (msg, err) => {
        console.error(chalk_1.default.red('[ERROR]'), msg);
        if (isDebug && err)
            console.error(chalk_1.default.gray(err));
    }
};
const ses = new client_sesv2_1.SESv2Client({
    region: REGION,
    endpoint: SES_ENDPOINT || undefined,
    credentials: { accessKeyId: ACCESS_KEY, secretAccessKey: SECRET_KEY },
});
const testSend = async () => {
    try {
        await ses.send(new client_sesv2_1.SendEmailCommand({
            FromEmailAddress: FROM_EMAIL,
            Destination: { ToAddresses: [FROM_EMAIL] }, // send to self first
            Content: {
                Simple: {
                    Subject: { Data: 'Test Email' },
                    Body: { Text: { Data: 'Hello from SES test.' } },
                },
            },
        }));
        console.log('Test email sent successfully');
    }
    catch (error) {
        console.error('Test send failed:', error);
    }
};
testSend();
