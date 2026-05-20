import { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { deletePost, fetchPosts } from '../api/posts';
import { useAuth } from '../context/AuthContext';

export default function Dashboard() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadPosts = async () => {
    setLoading(true);
    try {
      const { data } = await fetchPosts();
      setPosts(data);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load posts');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPosts();
  }, []);

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this post?')) return;
    await deletePost(id);
    setPosts((current) => current.filter((post) => post.id !== id));
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="page">
      <header className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p>Welcome, {user?.name}</p>
        </div>
        <div className="actions">
          <Link className="btn" to="/posts/new">
            New post
          </Link>
          <button type="button" className="btn-secondary" onClick={handleLogout}>
            Log out
          </button>
        </div>
      </header>

      {loading && <p>Loading posts...</p>}
      {error && <p className="error-banner">{error}</p>}

      {!loading && posts.length === 0 && <p>No posts yet. Create your first post.</p>}

      <ul className="post-list">
        {posts.map((post) => (
          <li key={post.id} className="post-card">
            <h2>{post.title}</h2>
            <p>{post.body}</p>
            <div className="post-actions">
              <Link to={`/posts/${post.id}/edit`}>Edit</Link>
              <button type="button" onClick={() => handleDelete(post.id)}>
                Delete
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
