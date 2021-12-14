declare global {
  namespace NodeJS {
    interface ProcessEnv {
      CUT_AMOUNT: string
      INFURA_PROJECT_ID: string
      INFURA_PROJECT_SECRET: string
      INFURA_HTTP: string
      INFURA_WSS: string
      MNEMONIC: string
      NETWORK_ID: string
    }
  }
}

export {}
