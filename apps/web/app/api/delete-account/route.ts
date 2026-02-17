import { NextRequest, NextResponse } from 'next/server'
import { createServiceRoleClient } from '@/lib/supabase-server'
import { createClient } from '@supabase/supabase-js'

export async function DELETE(request: NextRequest) {
  try {
    // Get the user's access token from the Authorization header
    const authHeader = request.headers.get('authorization')
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Missing authorization' }, { status: 401 })
    }

    const token = authHeader.substring(7)

    // Verify the token by creating a client with it
    const userClient = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser(token)

    if (authError || !user) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 })
    }

    const userId = user.id
    const supabase = createServiceRoleClient()

    // Delete child rows first (order matters for foreign keys)
    const { data: entryIds, error: entryIdsError } = await supabase
      .from('entries')
      .select('id')
      .eq('user_id', userId)

    if (entryIdsError) {
      throw entryIdsError
    }

    if (entryIds && entryIds.length > 0) {
      const ids = entryIds.map((e: { id: string }) => e.id)
      await supabase.from('travel_segments').delete().in('entry_id', ids).throwOnError()
      await supabase.from('work_shifts').delete().in('entry_id', ids).throwOnError()
    }

    // Delete entries
    await supabase.from('entries').delete().eq('user_id', userId).throwOnError()

    // Delete absences
    await supabase.from('absences').delete().eq('user_id', userId).throwOnError()

    // Delete profile
    await supabase.from('profiles').delete().eq('id', userId).throwOnError()

    // Delete storage files
    try {
      const { data: attachments } = await supabase.storage
        .from('attachments')
        .list(userId)
      if (attachments && attachments.length > 0) {
        const paths = attachments.map(f => `${userId}/${f.name}`)
        await supabase.storage.from('attachments').remove(paths)
      }
    } catch {
      // Storage bucket may not exist, continue
    }

    try {
      const { data: avatars } = await supabase.storage
        .from('avatars')
        .list(userId)
      if (avatars && avatars.length > 0) {
        const paths = avatars.map(f => `${userId}/${f.name}`)
        await supabase.storage.from('avatars').remove(paths)
      }
    } catch {
      // Storage bucket may not exist, continue
    }

    // Delete the auth user
    const { error: deleteError } = await supabase.auth.admin.deleteUser(userId)
    if (deleteError) {
      console.error('Failed to delete auth user:', deleteError)
      return NextResponse.json(
        { error: 'Failed to delete account' },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Delete account error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
