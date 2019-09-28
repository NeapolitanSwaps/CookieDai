/* eslint-disable */
const truffleAssert = require('truffle-assertions')
const { assertRevert } = require('./helpers/general')
const CookieRegistry = artifacts.require('CookieRegistry')

contract('CookieRegistry', accounts => {
  let cookieRegistry
  const user = accounts[0]

  beforeEach(async () => {
    cookieRegistry = await CookieRegistry.new({
      from: user
    })
  })

  it('user should be owner and admin', async () => {
    const admin = await cookieRegistry.getAddress('admin', {
      from: user
    })

    assert.equal(admin, user, 'user is admin')
  })

  it('only admin or owner should be able to set address', async () => {
    const result = await cookieRegistry.setAddress('admin', accounts[2], {
      from: user
    })

    expect(result.receipt.status).to.equal(true)
    truffleAssert.prettyPrintEmittedEvents(result)
    truffleAssert.eventEmitted(
      result,
      'LogSetAddress',
      event => {
        return event.name === 'admin' && event.addr === accounts[2]
      },
      'LogSetAddress should be emitted with correct parameters'
    )
  })

  it('revert when non-admin tries to set address', async () => {
    await assertRevert(
        cookieRegistry.setAddress('admin', accounts[2], {
        from: user
      })
    )
  })
})
