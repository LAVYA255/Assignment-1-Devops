import { useState } from 'react';

export default function App() {
  const [count, setCount] = useState(0);

  return (
    <div
      style={{
        fontFamily: 'system-ui, sans-serif',
        textAlign: 'center',
        paddingTop: 80,
      }}
    >
      <h1>Hello World from React</h1>
      <p>Built with Vite, served by Nginx inside a Docker container</p>
      <button
        onClick={() => setCount((c) => c + 1)}
        style={{ padding: '8px 16px', fontSize: 16, cursor: 'pointer' }}
      >
        clicked {count} times
      </button>
      <p style={{ color: '#666' }}>
        The counter proves this is a live React bundle, not a static page.
      </p>
    </div>
  );
}
