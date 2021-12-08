export function shouldHaveCorrectOwner(buyerAccount: string) {
  it('should have new owner', async function () {
    const { tokenId, instance } = this.context

    const newOwner = await instance.ownerOf(tokenId)

    expect(newOwner).to.be.eq(buyerAccount)
  })
}
