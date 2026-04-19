import { useState, useEffect } from 'react'
import { getProducts, getLowStock } from '../api/products'
import { getCategories } from '../api/categories'
import { getMovements } from '../api/movements'

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalProducts: 0,
    totalCategories: 0,
    totalMovements: 0,
    lowStock: []
  })

  useEffect(() => {
    loadStats()
  }, [])

  const loadStats = async () => {
    const [products, categories, movements, lowStock] = await Promise.all([
      getProducts(),
      getCategories(),
      getMovements(),
      getLowStock()
    ])
    setStats({
      totalProducts: products.data.length,
      totalCategories: categories.data.length,
      totalMovements: movements.data.length,
      lowStock: lowStock.data
    })
  }

  const cards = [
    { label: 'Productos', value: stats.totalProducts, icon: '📦', color: '#3b82f6' },
    { label: 'Categorías', value: stats.totalCategories, icon: '🏷️', color: '#8b5cf6' },
    { label: 'Movimientos', value: stats.totalMovements, icon: '🔄', color: '#22c55e' },
    { label: 'Stock bajo', value: stats.lowStock.length, icon: '⚠️', color: '#ef4444' },
  ]

  return (
    <div style={{ padding: '2rem' }}>
      <h1 style={{ marginBottom: '1.5rem' }}>📊 Dashboard</h1>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '1rem', marginBottom: '2rem' }}>
        {cards.map(card => (
          <div key={card.label} style={{ background: 'white', borderRadius: '8px', padding: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)', borderTop: `4px solid ${card.color}` }}>
            <div style={{ fontSize: '2rem' }}>{card.icon}</div>
            <div style={{ fontSize: '2rem', fontWeight: 'bold', color: card.color }}>{card.value}</div>
            <div style={{ color: '#64748b' }}>{card.label}</div>
          </div>
        ))}
      </div>

      {stats.lowStock.length > 0 && (
        <div style={{ background: 'white', borderRadius: '8px', padding: '1.5rem', boxShadow: '0 2px 6px rgba(0,0,0,0.1)' }}>
          <h2 style={{ marginBottom: '1rem', color: '#ef4444' }}>⚠️ Productos con stock bajo</h2>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead style={{ background: '#f8fafc' }}>
              <tr>
                {['Producto', 'Stock actual', 'Stock mínimo'].map(h => (
                  <th key={h} style={{ padding: '0.75rem 1rem', textAlign: 'left', borderBottom: '1px solid #e2e8f0' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {stats.lowStock.map(p => (
                <tr key={p.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                  <td style={{ padding: '0.75rem 1rem' }}>{p.name}</td>
                  <td style={{ padding: '0.75rem 1rem' }}>
                    <span style={{ background: '#fee2e2', color: '#ef4444', padding: '0.25rem 0.5rem', borderRadius: '4px' }}>
                      {p.stock} {p.unit}
                    </span>
                  </td>
                  <td style={{ padding: '0.75rem 1rem', color: '#64748b' }}>{p.min_stock}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {stats.lowStock.length === 0 && (
        <div style={{ background: '#dcfce7', borderRadius: '8px', padding: '1.5rem', textAlign: 'center', color: '#22c55e' }}>
          ✅ Todo el inventario está en niveles correctos
        </div>
      )}
    </div>
  )
}