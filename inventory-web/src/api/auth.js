import client from './client'

export const login = (email, password) =>
  client.post('/auth/login', { email, password })

export const register = (data) =>
  client.post('/auth/register', data)

export const getUsers = () =>
  client.get('/users/')

export const createUser = (data) =>
  client.post('/auth/register', data)

export const deleteUser = (id) =>
  client.delete(`/users/${id}`)