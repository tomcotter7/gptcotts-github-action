from argparse import ArgumentParser
from pinecone import Pinecone
import cohere
import uuid

def connect_to_pinecone(api_key: str) -> Pinecone:
    pinecone = Pinecone(api_key)
    return pinecone

def connect_to_cohere(api_key: str) -> cohere.Client:
    cohere_client = cohere.Client(api_key)
    return cohere_client

def convert_to_chunks(text: str, notes_class: str) -> list[dict]:

    headers = {1: "", 2: "", 3: "", 4: ""}

    contextualized_lines = []
    current_section = ""

    for line in text.splitlines():
        if line.startswith("#"):
            if len(current_section) > 0:
                chunk = ": ".join([val for val in headers.values() if len(val) > 0]) + ":" + current_section
                contextualized_lines.append({"header": headers[1], "class": notes_class, "text": chunk})
                current_section = ""
            level = line.count("#")
            if level in headers:
                headers[level] = line.replace("#", "").strip()
                for i in range(level + 1, 5):
                    try:
                        headers[i] = ""
                    except KeyError:
                        break

        elif len(line) == 0:
            pass

        else:
            current_section += line + "\n"

    if len(current_section) > 0:
        chunk = ": ".join([val for val in headers.values() if len(val) > 0]) + ":" + current_section
        contextualized_lines.append({"header": headers[1], "class": notes_class, "text": chunk})

    return contextualized_lines

def batch_embed(chunks: list[dict], cohere_api_key: str) -> list[dict]:
    results = []
    cohere_client = connect_to_cohere(cohere_api_key)
    batch_size = 96
    for i in range(0, len(chunks), batch_size):
        batch = chunks[i:i + batch_size]
        texts = [chunk["text"] for chunk in batch]
        embeddings = cohere_client.embed(
                texts=texts,
                model="embed-english-v3.0",
                input_type="search_document"
        )
        for idx, emb in enumerate(embeddings.embeddings): # type: ignore
            results.append({
                "id": str(uuid.uuid4()),
                "metadata": {"header": batch[i + idx]["header"], "class": batch[i + idx]["class"], "text": batch[i + idx]["text"]},
                "values": emb
            })
    return results

def upsert(pc: Pinecone, index: str, namespace: str, data: list[dict]):
    if len(data) == 0:
        print("No data to upsert")
        return

    pc_index = pc.Index(index)
    pc_index.upsert( # type: ignore
            namespace=namespace,
            vectors=data
    )
    print(f"Upserted {len(data)} items")


def main(
    api_key: str,
    cohere_api_key: str,
    index: str,
    namespace: str,
    changed_files: str
):

    pc = connect_to_pinecone(api_key)
    pc_index = pc.Index(index)
    if pc_index is None:
        raise ValueError(f"Index {index} not found")

    files = [f.split(".")[0] for f in changed_files.split(" ")]
    files = [f for f in files if len(f) > 0]

    dim = 1024
    for file in files:
        print(f"Processing file: {file}")
        old_data = pc_index.query(
                namespace=namespace,
                vector = [0.0 for _ in range(dim)],
                top_k = 500,
                filter = {
                    "class": {"$eq": file}
                }
        )['matches']

        ids = [match['id'] for match in old_data]
        if ids:
            pc_index.delete(ids=ids, namespace=namespace)
        
        try:
            with open(file + ".md", "r") as f:
                text = f.read()
            chunks = convert_to_chunks(text, file)
            data = batch_embed(chunks, cohere_api_key)
            upsert(pc, index, namespace, data)
        except FileNotFoundError:
            print(f"File {file}.md not found. Not uploading to pinecone")


if __name__ == "__main__":

    parser = ArgumentParser()
    parser.add_argument("--api_key", type=str, required=True)
    parser.add_argument("--cohere_api_key", type=str, required=True)
    parser.add_argument("--index", type=str, required=True)
    parser.add_argument("--namespace", type=str, required=True)
    parser.add_argument("--changed_files", type=str, required=True)

    args = parser.parse_args()

    main(**vars(args))


