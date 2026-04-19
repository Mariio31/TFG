import client from './client'

export const getMovements = () => client.get('/movements/')
export const createMovement = (data) => client.post('/movements/', data)