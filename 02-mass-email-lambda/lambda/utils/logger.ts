import chalk from 'chalk'

const isDebug = process.env.DEBUG_MODE === 'true'

export const log = {
    info: (msg: string) => console.log(chalk.cyan('[INFO]'), msg),
    debug: (msg: string) => isDebug && console.log(chalk.yellow('[DEBUG]'), msg),
    success: (msg: string) => console.log(chalk.green('[SUCCESS]'), msg),
    error: (msg: string, err?: any) => {
        console.error(chalk.red('[ERROR]'), msg)
        if (isDebug && err) console.error(chalk.gray(err))
    },
}
