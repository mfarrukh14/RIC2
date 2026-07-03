import React from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import './services/httpAuth'
import App from './App.jsx'
import { SessionProvider } from './context/SessionContext.jsx'

createRoot(document.getElementById('root')).render(
    <SessionProvider>
        <App />
    </SessionProvider>
)
