import { useState, useEffect } from 'react'
import { getMovements, createMovement } from '../api/movements'
import { getProducts } from '../api/products'

export default function Movements() {
  const [movements, setMovements] = useState([])
  const [products, setProducts] = useState([])
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({
    product_id: '',
    product_name: '',
    type: 'entrada',
    quantity: 1,
    reason: '',
    notes: '',
    reference: ''
  })

  useEffect(() => {
    loadMovements()
    loadProducts()
  }, [])

  const loadMovements = async () => {
    const res = await getMovements()
    setMovements(res.data)
  }

  const loadProducts = async () => {
    const res = await getProducts()
    setProducts(res.data)
  }

  const handleProductChange = (e) => {
    const product = products.find(p => p.id === parseInt(e.target.value))
    setForm({ ...form, product_id: product.id, product_name: product.name })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    await createMovement(form)
    setShowForm(false)
    setForm({ product_id: '', product_name: '', type: 'entrada', quantity: 1, reason: '', notes: '', reference: '' })
    loadMovements()
  }

  const typeColor = (type) => {
    if (type === 'entrada') return { bg: '#dcfce7', color: '#22c55e' }
    if (type === 'salida') return { bg: '#fee2e2', color: '#ef4444' }
    return { bg: '#fef9c3', color: '#eab308' }
  }

  return (
    <div style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>🔄 Movimientos</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          style={{ background: '#3b82f6', color: 'white', border: 'none', padding: '0.5rem 1rem', borderRadius: '4px', cursor: 'pointer' }}
        >
          {showForm ? 'Cancelar' : '+ Nuevo movimiento'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} style={{ background: 'white', padding: '1.5rem', borderRadius: '8px', marginBottom: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <select
              value={form.product_id}
              onChange={handleProductChange}
              required
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            >
              <option value="">Selecciona un producto *</option>
              {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </select>
            <select
              value={form.type}
              onChange={e => setForm({...form, type: e.target.value})}
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            >
              <option value="entrada">Entrada</option>
              <option value="salida">Salida</option>
              <option value="ajuste">Ajuste</option>
            </select>
            <input
              type="number"
              placeholder="Cantidad *"
              value={form.quantity}
              onChange={e => setForm({...form, quantity: parseInt(e.target.value)})}
              min="1"
              required
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
            <input
              placeholder="Referencia (nº factura, orden...)"
              value={form.reference}
              onChange={e => setForm({...form, reference: e.target.value})}
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
            <input
              placeholder="Motivo"
              value={form.reason}
              onChange={e => setForm({...form, reason: e.target.value})}
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
            <input
              placeholder="Notas adicionales"
              value={form.notes}
              onChange={e => setForm({...form, notes: e.target.value})}
              style={{ padding: '0.5rem', borderRadius: '4px', border: '1px solid #ddd' }}
            />
          </div>
          <button type="submit" style={{ marginTop: '1rem', background: '#22c55e', color: 'white', border: 'none', padding: '0.5rem 1.5rem', borderRadius: '4px', cursor: 'pointer' }}>
            Registrar movimiento
          </button>
        </form>
      )}

      <div style={{ background: 'white', borderRadius: '8px', boxShadow: '0 2px 6px rgba(0,0,0,0.1)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead style={{ background: '#f8fafc' }}>
            <tr>
              {['Producto', 'Tipo', 'Cantidad', 'Motivo', 'Referencia', 'Fecha'].map(h => (
                <th key={h} style={{ padding: '0.75rem 1rem', textAlign: 'left', borderBottom: '1px solid #e2e8f0' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {movements.map(m => (
              <tr key={m.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                <td style={{ padding: '0.75rem 1rem' }}>{m.product_name}</td>
                <td style={{ padding: '0.75rem 1rem' }}>
                  <span style={{ background: typeColor(m.type).bg, color: typeColor(m.type).color, padding: '0.25rem 0.5rem', borderRadius: '4px', fontSize: '0.85rem' }}>
                    {m.type}
                  </span>
                </td>
                <td style={{ padding: '0.75rem 1rem' }}>{m.quantity}</td>
                <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{m.reason || '-'}</td>
                <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{m.reference || '-'}</td>
                <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{new Date(m.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {movements.length === 0 && <p style={{ textAlign: 'center', padding: '2rem', color: '#94a3b8' }}>No hay movimientos aún</p>}
      </div>
    </div>
  )
}