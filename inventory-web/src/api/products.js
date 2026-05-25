import client from './client'

export const getProducts = () => client.get('/products/')
export const getProduct = (id) => client.get(`/products/${id}`)
export const createProduct = (data) => client.post('/products/', data)
export const updateProduct = (id, data) => client.put(`/products/${id}`, data)
export const deleteProduct = (id) => client.delete(`/products/${id}`)
export const getLowStock = () => client.get('/products/low-stock')

export const uploadProductImage = async (id, file) => {
  const token = localStorage.getItem('token')
  const formData = new FormData()
  formData.append('file', file)
  return fetch(`http://127.0.0.1:8000/products/${id}/image`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData
  })
}

export const getProductImageUrl = (id) => `http://127.0.0.1:8000/products/${id}/image?t=${Date.now()}`

export const deleteProductImage = async (id) => {
  const token = localStorage.getItem('token')
  return fetch(`http://127.0.0.1:8000/products/${id}/image`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` }
  })
}