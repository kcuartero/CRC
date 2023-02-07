describe('CRC E2E Test', () => {
  it('Check API to return OK status code and visitor count', () => {
    cy.request('https://kcuart-gw-76btakhm.uc.gateway.dev/count')
      .then((response) => {
      expect(response.status).to.eq(200) //check http response if OK(200)
      expect(response.body).to.have.property('count') //check if the API returns count value
    }) 
  })
})
      