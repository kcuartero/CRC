describe('CRC E2E Test', () => {
  it('Check API to return OK status code and visitor count', () => {
    cy.request('https://kcuartero-gw-5u3b1jgg.uc.gateway.dev/count')
      .then((response) => {
      expect(response.status).to.eq(200) //check http response if OK(200)
      expect(response.body).to.have.property('count') //check if the API returns count value
    }) 
  })
})
      