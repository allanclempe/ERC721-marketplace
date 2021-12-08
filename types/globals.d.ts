declare global {
  namespace NodeJS {
    interface ProcessEnv {
      CUT_AMOUNT: string
    }
  }
}

export {}
