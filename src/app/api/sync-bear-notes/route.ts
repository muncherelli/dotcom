import { NextResponse } from 'next/server'
import { prisma } from '@/lib/prisma'
import matter from 'gray-matter'
import { plistDateToJSDate } from '@/lib/apple-plist'
import { markdownToHtml, getSlug } from '@/lib/markdown'

export async function POST(request: Request) {
  try {
    // verify api key
    const authHeader = request.headers.get('authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const apiKey = authHeader.split(' ')[1]
    if (apiKey !== process.env.API_KEY) {
      return NextResponse.json({ error: 'Invalid API key' }, { status: 401 })
    }

    const notes = await request.json()

    for (const note of notes) {
      // first, upsert into bear.ZSFNOTE
      await prisma.bearNote.upsert({
        where: {
          Z_PK: note.Z_PK,
        },
        update: {
          Z_ENT: note.Z_ENT,
          Z_OPT: note.Z_OPT,
          ZARCHIVED: note.ZARCHIVED,
          ZENCRYPTED: note.ZENCRYPTED,
          ZHASFILES: note.ZHASFILES,
          ZHASIMAGES: note.ZHASIMAGES,
          ZHASSOURCECODE: note.ZHASSOURCECODE,
          ZLOCKED: note.ZLOCKED,
          ZORDER: note.ZORDER,
          ZPERMANENTLYDELETED: note.ZPERMANENTLYDELETED,
          ZPINNED: note.ZPINNED,
          ZSHOWNINTODAYWIDGET: note.ZSHOWNINTODAYWIDGET,
          ZSKIPSYNC: note.ZSKIPSYNC,
          ZTODOCOMPLETED: note.ZTODOCOMPLETED,
          ZTODOINCOMPLETED: note.ZTODOINCOMPLETED,
          ZTRASHED: note.ZTRASHED,
          ZVERSION: note.ZVERSION,
          ZPASSWORD: note.ZPASSWORD,
          ZSERVERDATA: note.ZSERVERDATA,
          ZARCHIVEDDATE: note.ZARCHIVEDDATE,
          ZCONFLICTUNIQUEIDENTIFIERDATE: note.ZCONFLICTUNIQUEIDENTIFIERDATE,
          ZCREATIONDATE: note.ZCREATIONDATE,
          ZLOCKEDDATE: note.ZLOCKEDDATE,
          ZMODIFICATIONDATE: note.ZMODIFICATIONDATE,
          ZORDERDATE: note.ZORDERDATE,
          ZPINNEDDATE: note.ZPINNEDDATE,
          ZTRASHEDDATE: note.ZTRASHEDDATE,
          ZCONFLICTUNIQUEIDENTIFIER: note.ZCONFLICTUNIQUEIDENTIFIER,
          ZENCRYPTIONUNIQUEIDENTIFIER: note.ZENCRYPTIONUNIQUEIDENTIFIER,
          ZLASTEDITINGDEVICE: note.ZLASTEDITINGDEVICE,
          ZSUBTITLE: note.ZSUBTITLE,
          ZTEXT: note.ZTEXT,
          ZTITLE: note.ZTITLE,
          ZUNIQUEIDENTIFIER: note.ZUNIQUEIDENTIFIER,
        },
        create: {
          Z_PK: note.Z_PK,
          Z_ENT: note.Z_ENT,
          Z_OPT: note.Z_OPT,
          ZARCHIVED: note.ZARCHIVED,
          ZENCRYPTED: note.ZENCRYPTED,
          ZHASFILES: note.ZHASFILES,
          ZHASIMAGES: note.ZHASIMAGES,
          ZHASSOURCECODE: note.ZHASSOURCECODE,
          ZLOCKED: note.ZLOCKED,
          ZORDER: note.ZORDER,
          ZPERMANENTLYDELETED: note.ZPERMANENTLYDELETED,
          ZPINNED: note.ZPINNED,
          ZSHOWNINTODAYWIDGET: note.ZSHOWNINTODAYWIDGET,
          ZSKIPSYNC: note.ZSKIPSYNC,
          ZTODOCOMPLETED: note.ZTODOCOMPLETED,
          ZTODOINCOMPLETED: note.ZTODOINCOMPLETED,
          ZTRASHED: note.ZTRASHED,
          ZVERSION: note.ZVERSION,
          ZPASSWORD: note.ZPASSWORD,
          ZSERVERDATA: note.ZSERVERDATA,
          ZARCHIVEDDATE: note.ZARCHIVEDDATE,
          ZCONFLICTUNIQUEIDENTIFIERDATE: note.ZCONFLICTUNIQUEIDENTIFIERDATE,
          ZCREATIONDATE: note.ZCREATIONDATE,
          ZLOCKEDDATE: note.ZLOCKEDDATE,
          ZMODIFICATIONDATE: note.ZMODIFICATIONDATE,
          ZORDERDATE: note.ZORDERDATE,
          ZPINNEDDATE: note.ZPINNEDDATE,
          ZTRASHEDDATE: note.ZTRASHEDDATE,
          ZCONFLICTUNIQUEIDENTIFIER: note.ZCONFLICTUNIQUEIDENTIFIER,
          ZENCRYPTIONUNIQUEIDENTIFIER: note.ZENCRYPTIONUNIQUEIDENTIFIER,
          ZLASTEDITINGDEVICE: note.ZLASTEDITINGDEVICE,
          ZSUBTITLE: note.ZSUBTITLE,
          ZTEXT: note.ZTEXT,
          ZTITLE: note.ZTITLE,
          ZUNIQUEIDENTIFIER: note.ZUNIQUEIDENTIFIER,
        },
      })

      // then, extract title and slug from frontmatter or ZTITLE and upsert into dbo.Notes
      const { data: frontMatter, content: markdownContent } = matter(
        note.ZTEXT || ''
      )
      const title = frontMatter.title || note.ZTITLE
      // get the slug from frontmatter or generate from title (will be used after migration)
      const slug = getSlug(frontMatter.slug, title)

      // convert markdown to HTML
      let htmlContent = ''
      try {
        htmlContent = await markdownToHtml(markdownContent)
      } catch (error) {
        console.error('Error converting markdown to HTML:', error)
      }

      // convert PLIST dates to JavaScript Date objects
      const createdAt = plistDateToJSDate(note.ZCREATIONDATE)
      const updatedAt = plistDateToJSDate(note.ZMODIFICATIONDATE)
      const archivedAt = plistDateToJSDate(note.ZARCHIVEDDATE)
      const lockedAt = plistDateToJSDate(note.ZLOCKEDDATE)
      const pinnedAt = plistDateToJSDate(note.ZPINNEDDATE)
      const trashedAt = plistDateToJSDate(note.ZTRASHEDDATE)

      // process tags from frontMatter
      const tagNames = []
      if (frontMatter.tags) {
        if (Array.isArray(frontMatter.tags)) {
          // if tags are already an array
          tagNames.push(...frontMatter.tags.map((tag) => String(tag).trim()))
        } else {
          // if tags are a comma-separated string
          tagNames.push(...String(frontMatter.tags).split(',').map((tag) => tag.trim()))
        }
      }

      // filter out empty tags
      const validTagNames = tagNames.filter((tag) => tag.length > 0)

      // use a transaction to ensure all database operations succeed or fail together
      await prisma.$transaction(async (tx) => {
        // check if note exists
        const existingNote = await tx.$queryRawUnsafe(
          `SELECT [ID] FROM [dbo].[Notes] WHERE [ID] = ${note.Z_PK}`
        )
        
        const noteExists = Array.isArray(existingNote) && existingNote.length > 0
        
        if (noteExists) {
          // update existing note
          await tx.$executeRawUnsafe(`
            UPDATE [dbo].[Notes]
            SET 
              [Title] = N'${title?.replace(/'/g, "''") || ''}',
              [Slug] = N'${slug?.replace(/'/g, "''") || ''}',
              [Markdown] = N'${note.ZTEXT?.replace(/'/g, "''") || ''}',
              [HTML] = N'${htmlContent?.replace(/'/g, "''") || ''}',
              [UpdatedAt] = ${updatedAt ? `'${updatedAt.toISOString()}'` : 'GETDATE()'},
              [ArchivedAt] = ${archivedAt ? `'${archivedAt.toISOString()}'` : 'NULL'},
              [LockedAt] = ${lockedAt ? `'${lockedAt.toISOString()}'` : 'NULL'},
              [PinnedAt] = ${pinnedAt ? `'${pinnedAt.toISOString()}'` : 'NULL'},
              [TrashedAt] = ${trashedAt ? `'${trashedAt.toISOString()}'` : 'NULL'}
            WHERE [ID] = ${note.Z_PK}
          `)
        } else {
          // create new note
          await tx.$executeRawUnsafe(`
            INSERT INTO [dbo].[Notes] (
              [ID], [Title], [Slug], [Markdown], [HTML], 
              [CreatedAt], [UpdatedAt], [ArchivedAt], [LockedAt], [PinnedAt], [TrashedAt]
            ) VALUES (
              ${note.Z_PK},
              N'${title?.replace(/'/g, "''") || ''}',
              N'${slug?.replace(/'/g, "''") || ''}',
              N'${note.ZTEXT?.replace(/'/g, "''") || ''}',
              N'${htmlContent?.replace(/'/g, "''") || ''}',
              ${createdAt ? `'${createdAt.toISOString()}'` : 'GETDATE()'},
              ${updatedAt ? `'${updatedAt.toISOString()}'` : 'GETDATE()'},
              ${archivedAt ? `'${archivedAt.toISOString()}'` : 'NULL'},
              ${lockedAt ? `'${lockedAt.toISOString()}'` : 'NULL'},
              ${pinnedAt ? `'${pinnedAt.toISOString()}'` : 'NULL'},
              ${trashedAt ? `'${trashedAt.toISOString()}'` : 'NULL'}
            )
          `)
        }

        if (validTagNames.length > 0) {
          // delete existing note-tag relationships for this note
          await tx.$executeRawUnsafe(
            `DELETE FROM [dbo].[NoteTags] WHERE [NoteID] = ${note.Z_PK}`
          )

          // process each tag
          for (const tagName of validTagNames) {
            // find or create the tag - safely escape the tag name
            const escapedTagName = tagName.replace(/'/g, "''")
            const tag = await tx.$queryRawUnsafe(
              `SELECT [ID] FROM [dbo].[Tags] WHERE [Name] = N'${escapedTagName}'`
            )

            let tagId
            if (!tag || (Array.isArray(tag) && tag.length === 0)) {
              // create new tag
              await tx.$executeRawUnsafe(
                `INSERT INTO [dbo].[Tags] ([Name]) 
                 VALUES (N'${escapedTagName}')`
              )
              
              // get the new tag ID
              const newTag = await tx.$queryRawUnsafe(
                `SELECT [ID] FROM [dbo].[Tags] WHERE [Name] = N'${escapedTagName}'`
              )
              tagId = Array.isArray(newTag) && newTag.length > 0 ? newTag[0].ID : null
            } else {
              tagId = Array.isArray(tag) && tag.length > 0 ? tag[0].ID : null
            }

            if (tagId) {
              // create note-tag relationship
              await tx.$executeRawUnsafe(
                `INSERT INTO [dbo].[NoteTags] ([NoteID], [TagID])
                 VALUES (${note.Z_PK}, ${tagId})`
              )
            }
          }
        }
      })
    }

    return NextResponse.json({ message: 'Notes synced successfully' })
  } catch (error) {
    console.error('Error syncing notes:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}