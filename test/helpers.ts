import BN from 'bn.js'
import { AllEvents, Transfer } from '../types/truffle-contracts/ERC721Mock'

export function assertEventOfType(
  response: Truffle.TransactionResponse<AllEvents>,
  eventName: string,
  index: number
) {
  assert.equal(
    response.logs[index].event,
    eventName,
    `${eventName} event should fire.`
  )
}

export function assertEventsOfType(
  response: Truffle.TransactionResponse<AllEvents>,
  ...eventNames: Array<string>
) {
  eventNames.forEach((eventName, index) => {
    assert.equal(
      response.logs[index].event,
      eventName,
      `${eventName} event should fire.`
    )
  })
}

export async function assertThrown(fn: () => Promise<any>, reason: string) {
  let err = null

  try {
    await fn()
  } catch (error: any) {
    err = error.reason
  }

  expect(err).to.be.eq(reason)
}

export function calcuCutAmountInWei(
  saleAmountInWei: string | BN,
  cutPerc: BN | string
) {
  return new BN(cutPerc).mul(new BN(saleAmountInWei)).div(new BN(10000))
}

export function calcProceeds(
  saleAmountInWei: string | BN,
  cutPerc: string | BN
) {
  const saleAmount = new BN(saleAmountInWei)
  const cutAmount = calcuCutAmountInWei(saleAmount, cutPerc)

  return new BN(saleAmount).sub(cutAmount)
}

export function getTokenId(
  transaction: Truffle.TransactionResponse<AllEvents>,
  index = 0
) {
  return (transaction as Truffle.TransactionResponse<Transfer>).logs[
    index
  ].args.tokenId.toNumber()
}
