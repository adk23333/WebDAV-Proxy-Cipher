export {}
declare global {
  interface PasswdInfo {
    password: string
    encType: string
    describe: string
    enable: boolean
    encName: boolean
    encNameSuffix: string
    encPath: string[]
  }
}
