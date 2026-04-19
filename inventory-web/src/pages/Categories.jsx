import { useState, useEffect } from 'react'
import { getCategories, createCategory, deleteCategory } from '../api/categories'

export default function Categories() {
  const [categories, setCategories] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', description: '', color: '#6B7F5B' })

  useEffect(() => {
    loadCategories()
  }, [])

  const loadCategories = async () => {
    const res = await getCategories()
    setCategories(res.data)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    await createCategory(form)
    setShowForm(false)
    setForm({ name: '', description: '', color: '#6B7F5B' })
    loadCategories()
  }

  const handleDelete = async (id) => {
    if (confirm('¿Eliminar categoría?')) {
      await deleteCategory(id)
      loadCategories()
    }
  }

  return (
    <div style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>🏷️ Categorías</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          style={{ background: '#3b82f6', color: 'white', border: 'none', padding: '0.5rem 1rem', borderRadius: '4px', cursor: 'pointer' }}
        >
          {showForm ? 'Cancelar' : '+ Nueva categoría'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} style={{ background: 'white', padding: '1.5rem', borderRadius: '8px', marginBottom: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
            <input
              placeholder="Nombre *"
              value={form.name}
              onChange={e => setForm({...form, name: e.target.value})}
              required
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
            <input
              placeholder="Descripción"
              value={form.description}
              onChange={e => setForm({...form, description: e.target.value})}
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <label>Color:</label>
              <input
                type="color"
                value={form.color}
                onChange={e => setForm({...form, color: e.target.value})}
                style={{ width: '50px', height: '35px', borderRadius: '4px', border: '1px solid #ddd', cursor: 'pointer' }}
              />
            </div>
          </div>
          <button type="submit" style={{ marginTop: '1rem', background: '#22c55e', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '4px', cursor: 'pointer' }}>
            Guardar categoría
          </button>
        </form>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: '1rem' }}>
        {categories.map(c => (
          <div key={c.id} style={{ background: 'white', borderRadius: '8px', padding: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)', borderLeft: `4px solid ${c.color}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start' }}>
              <div>
                <h3 style={{ margin: 0, marginBottom: '0.5rem' }}>{c.name}</h3>
                <p style={{ margin: 0, color: '#64748b', fontSize: '0.9rem' }}>{c.description || 'Sin descripción'}</p>
              </div>
              <button
                onClick={() => handleDelete(c.id)}
                style={{ background: '#ef4444', color: 'white', border: 'none', padding: '0.25rem 0.75rem', borderRadius: '4px', cursor: 'pointer' }}
              >
                Eliminar
              </button>
            </div>
          </div>
        ))}
        {categories.length === 0 && <p style={{ color: '#94a3b8' }}>No hay categorías aún</p>}
      </div>
    </div>
  )
}