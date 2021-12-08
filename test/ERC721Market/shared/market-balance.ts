import { calcProceeds, calcuCutAmountInWei } from '../../helpers'

export function shouldHaveCorrectBalance(sellerAccount: string) {
  describe('sale balance tests', () => {
    it(`should have added credit to the seller`, async function () {
      const { instance, saleAmountInWei } = this.context

      const sellerBalance = await instance.getWithdrawBalance(sellerAccount)
      const sellerProceeds = calcProceeds(
        saleAmountInWei,
        process.env.CUT_AMOUNT
      )

      expect(sellerBalance.toString()).to.be.eq(sellerProceeds.toString())
    })

    it(`should have locked cut in contract`, async function () {
      const { instance, saleAmountInWei } = this.context

      const contractBalance = await instance.getWithdrawBalance(
        instance.address
      )

      const cutAmountInWei = calcuCutAmountInWei(
        saleAmountInWei,
        process.env.CUT_AMOUNT
      )

      expect(contractBalance.toString()).to.be.eq(cutAmountInWei.toString())
    })
  })
}
