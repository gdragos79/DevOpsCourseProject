// apps/frontend/src/components/PostUser.jsx
import { useState } from "react";
import { api } from "../lib/api";

export default function PostUser() {
  const [formData, setFormData] = useState({
    name: "",
    age: "",
    email: "",
  });
  const [submitting, setSubmitting] = useState(false);

  const handleChange = (e) => {
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      await api.post("/api/form", {
        name: formData.name,
        age: Number(formData.age),
        email: formData.email,
      });

      alert("User created successfully");
      setFormData({ name: "", age: "", email: "" });
    } catch (error) {
      const apiMessage = error?.response?.data?.error;
      if (error?.response?.status === 409 && apiMessage === "The user already exists") {
        alert("The user already exists");
      } else {
        alert(`Failed to create user: ${apiMessage || error.message}`);
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <h1>Create User</h1>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="name">Name</label>
          <input
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
          />
        </div>

        <div>
          <label htmlFor="age">Age</label>
          <input
            id="age"
            name="age"
            type="number"
            value={formData.age}
            onChange={handleChange}
            required
          />
        </div>

        <div>
          <label htmlFor="email">Email</label>
          <input
            id="email"
            name="email"
            type="email"
            value={formData.email}
            onChange={handleChange}
            required
          />
        </div>

        <button type="submit" disabled={submitting}>
          {submitting ? "Creating..." : "Create User"}
        </button>
      </form>
    </div>
  );
}
