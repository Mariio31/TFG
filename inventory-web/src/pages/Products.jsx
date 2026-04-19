import { useState, useEffect } from 'react'
import { getProducts, createProduct, deleteProduct } from '../api/products'
import { getCategories } from '../api/categories'

export default function Products() {
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    name: '', sku: '', description: '', category_id: '',
    price: 0, cost: 0, stock: 0, min_stock: 5, unit: 'unidad', supplier: ''
  })

  useEffect(() => {
    loadProducts()
    loadCategories()
  }, [])

  const loadProducts = async () => {
    const res = await getProducts()
    setProducts(res.data)
  }

  const loadCategories = async () => {
    const res = await getCategories()
    setCategories(res.data)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    await createProduct(form)
    setShowForm(false)
    setForm({ name: '', sku: '', description: '', category_id: '', price: 0, cost: 0, stock: 0, min_stock: 5, unit: 'unidad', supplier: '' })
    loadProducts()
  }

  const handleDelete = async (id) => {
    if (confirm('¿Eliminar producto?')) {
      await deleteProduct(id)
      loadProducts()
    }
  }

  return (
    <div style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>📦 Productos</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          style={{ background: '#3b82f6', color: 'white', border: 'none', padding: '0.5rem 1rem', borderRadius: '4px', cursor: 'pointer' }}
        >
          {showForm ? 'Cancelar' : '+ Nuevo producto'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} style={{ background: 'white', padding: '1.5rem', borderRadius: '8px', marginBottom: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <input placeholder="Nombre *" value={form.name} onChange={e => setForm({...form, name: e.target.value})} required style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <input placeholder="SKU" value={form.sku} onChange={e => setForm({...form, sku: e.target.value})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <input placeholder="Proveedor" value={form.supplier} onChange={e => setForm({...form, supplier: e.target.value})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <select value={form.category_id} onChange={e => setForm({...form, category_id: e.target.value})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}>
              <option value="">Sin categoría</option>
              {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
            <input type="number" placeholder="Precio" value={form.price} onChange={e => setForm({...form, price: parseFloat(e.target.value)})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <input type="number" placeholder="Coste" value={form.cost} onChange={e => setForm({...form, cost: parseFloat(e.target.value)})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <input type="number" placeholder="Stock inicial" value={form.stock} onChange={e => setForm({...form, stock: parseInt(e.target.value)})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
            <input type="number" placeholder="Stock mínimo" value={form.min_stock} onChange={e => setForm({...form, min_stock: parseInt(e.target.value)})} style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }} />
          </div>
          <button type="submit" style={{ marginTop: '1rem', background: '#22c55e', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '4px', cursor: 'pointer' }}>
            Guardar producto
          </button>
        </form>
      )}

      <div style={{ background: 'white', borderRadius: '8px', boxShadow: '0 2px 6px rgba(0,0,0,0.1)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead style={{ background: '#f8fafc' }}>
            <tr>
              {['Nombre', 'SKU', 'Stock', 'Precio', 'Proveedor', 'Acciones'].map(h => (
                <th key={h} style={{ padding: '0.75rem 1rem', textAlign: 'left', borderBottom: '1px solid #e2e8f0' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {products.map(p => (
              <tr key={p.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                <td style={{ padding: '0.75rem 1rem' }}>{p.name}</td>
                <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{p.sku || '-'}</td>
                <td style={{ padding: '0.75rem 1rem' }}>
                  <span style={{ background: p.stock <= p.min_stock ? '#fee2e2' : '#dcfce7', color: p.stock <= p.min_stock ? '#ef4444' : '#22c55e', padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.85rem' }}>
                    {p.stock} {p.unit}
                  </span>
                </td>
                <td style={{ padding: '0.75rem 1rem' }}>{p.price}€</td>
                <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{p.supplier || '-'}</td>
                <td style={{ padding: '0.75rem 1rem' }}>
                  <button onClick={() => handleDelete(p.id)} style={{ background: '#ef4444', color: 'white', border: 'none', padding: '0.25rem 0.75rem', borderRadius: '4px', cursor: 'pointer' }}>
                    Eliminar
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {products.length === 0 && <p style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>No hay productos aún</p>}
      </div>
    </div>
  )
}