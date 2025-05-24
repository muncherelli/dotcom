import { unified } from 'unified'
import remarkParse from 'remark-parse'
import remarkHtml from 'remark-html'

/**
 * Converts Markdown content to HTML with optional custom processing
 * 
 * @param markdown The markdown content to convert
 * @returns The HTML string
 */
export async function markdownToHtml(markdown: string): Promise<string> {
  try {
    const processor = unified()
      .use(remarkParse) // Parse markdown content
      .use(remarkHtml) // Convert to HTML

    // ==================================================
    // CUSTOM FILTERS AREA - START
    // Add your custom remark plugins or transformations here
    // Example:
    // .use(customPlugin, { option: value })
    // .use(anotherPlugin)
    // ==================================================

    // ==================================================
    // CUSTOM FILTERS AREA - END
    // ==================================================
    
    const file = await processor.process(markdown)
    return String(file)
  } catch (error) {
    console.error('Error converting markdown to HTML:', error)
    return '' // Return empty string on error
  }
}

/**
 * Extracts the title from markdown content if available
 * 
 * @param markdown The markdown content
 * @returns The extracted title or undefined
 */
export function extractTitleFromMarkdown(markdown: string): string | undefined {
  // Simple regex to find the first heading
  const titleMatch = markdown.match(/^#\s+(.+)$/m)
  return titleMatch ? titleMatch[1].trim() : undefined
}

/**
 * Generates a URL-friendly slug from a string
 * 
 * @param text The text to convert to a slug
 * @returns A URL-friendly slug
 */
export function generateSlug(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^\w\s-]/g, '') // Remove special characters
    .replace(/\s+/g, '-')     // Replace spaces with hyphens
    .replace(/--+/g, '-')     // Replace multiple hyphens with single hyphen
    .trim()                   // Trim whitespace
    .replace(/^-+|-+$/g, '')  // Remove leading/trailing hyphens
}

/**
 * Gets a slug from frontmatter or generates one from title
 * 
 * @param frontMatterSlug The slug from frontmatter, if available
 * @param title The title to use for generating a slug if frontMatterSlug is empty
 * @returns A URL-friendly slug
 */
export function getSlug(frontMatterSlug: string | undefined, title: string): string {
  if (frontMatterSlug && frontMatterSlug.trim() !== '') {
    return frontMatterSlug.trim();
  }
  
  return generateSlug(title);
}