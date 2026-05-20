import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { createPost, fetchPost, updatePost } from '../api/posts';

export default function PostForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();
  const [form, setForm] = useState({ title: '', body: '' });
  const [errors, setErrors] = useState([]);
  const [loading, setLoading] = useState(isEdit);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!isEdit) return;

    const load = async () => {
      try {
        const { data } = await fetchPost(id);
        setForm({ title: data.title, body: data.body || '' });
      } catch (err) {
        setErrors([err.response?.data?.error || 'Failed to load post']);
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id, isEdit]);

  const validate = () => {
    const next = [];
    if (!form.title.trim()) next.push('Title is required');
    setErrors(next);
    return next.length === 0;
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!validate()) return;

    setSubmitting(true);
    try {
      if (isEdit) {
        await updatePost(id, form);
      } else {
        await createPost(form);
      }
      navigate('/dashboard');
    } catch (err) {
      setErrors(err.response?.data?.errors || ['Save failed']);
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) return <p className="page">Loading post...</p>;

  return (
    <div className="page auth-card">
      <h1>{isEdit ? 'Edit post' : 'Create post'}</h1>
      {errors.length > 0 && (
        <ul className="error-list">
          {errors.map((error) => (
            <li key={error}>{error}</li>
          ))}
        </ul>
      )}
      <form onSubmit={handleSubmit}>
        <label>
          Title
          <input
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            required
          />
        </label>
        <label>
          Body
          <textarea
            rows={6}
            value={form.body}
            onChange={(e) => setForm({ ...form, body: e.target.value })}
          />
        </label>
        <div className="actions">
          <button type="submit" disabled={submitting}>
            {submitting ? 'Saving...' : 'Save'}
          </button>
          <Link className="btn-secondary" to="/dashboard">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  );
}
