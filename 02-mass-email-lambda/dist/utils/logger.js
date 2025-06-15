"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.log = void 0;
const chalk_1 = __importDefault(require("chalk"));
const isDebug = process.env.DEBUG_MODE === 'true';
exports.log = {
    info: (msg) => console.log(chalk_1.default.cyan('[INFO]'), msg),
    debug: (msg) => isDebug && console.log(chalk_1.default.yellow('[DEBUG]'), msg),
    success: (msg) => console.log(chalk_1.default.green('[SUCCESS]'), msg),
    error: (msg, err) => {
        console.error(chalk_1.default.red('[ERROR]'), msg);
        if (isDebug && err)
            console.error(chalk_1.default.gray(err));
    },
};
