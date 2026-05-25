import client from './client'

export const getMovements = () => client.get('/movements/')

export const createMovement = (data) => client.post('/movements/', data)

export const updateMovement = (id, data) =>
  client.put(`/movements/${id}`, {
    product_id: parseInt(data.product_id),
    product_name: data.product_name,
    quantity: parseInt(data.quantity),
    type: data.type.toLowerCase(),
    reason: data.reason || null,
    notes: data.notes || null,
    reference: data.reference || null
  })