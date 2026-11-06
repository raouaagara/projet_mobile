# Category Knowledge Base

This folder contains the data used by the AI (OpenAI / Gemini) to generate skill test questions.

## category-knowledge.json

A JSON file mapping each category to text content. The AI uses this content as the primary source when generating questions.

### Format

```json
{
  "Category Name": "Text describing concepts, definitions, and key facts for this category. The AI will generate questions based on this content."
}
```

### How to add or update knowledge

1. Edit `category-knowledge.json`
2. Add a new key for your category (must match the category name in the app)
3. Write clear, factual content: definitions, concepts, tools, best practices
4. Restart the SkillTestsMicroService

The more detailed and accurate the knowledge, the better the AI-generated questions.
