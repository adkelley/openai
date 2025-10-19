## File uploads
 - Upload the raw file with POST /v1/files (multipart form; include purpose=assistants). Response returns a file_id.
  - Create a vector store if needed with POST /v1/vector_stores (optionally pass file_ids to ingest immediately).
  - Attach the uploaded file to the store via POST /v1/vector_stores/{vector_store_id}/files with body { "file_id": "<from upload>" }.
  - For bulk ingestion, use POST /v1/vector_stores/{vector_store_id}/file_batches and supply multiple file_ids.
  - Track ingestion with GET /v1/vector_stores/{vector_store_id}/files, inspect an individual file with GET /v1/vector_stores/{vector_store_id}/files/
    {file_id}, and remove it using DELETE /v1/vector_stores/{vector_store_id}/files/{file_id}.
