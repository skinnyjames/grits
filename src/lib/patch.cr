@[Link("git2")]
lib LibGit
  type Patch = Void*

  fun patch_from_diff = git_patch_from_diff(out : Patch*, diff : Diff, idx : LibC::SizeT) : LibC::Int
  fun patch_from_blobs = git_patch_from_blobs(out : Patch*, old_blob : Blob, old_as_path : LibC::Char*, new_blob : Blob, new_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_from_blob_and_buffer = git_patch_from_blob_and_buffer(out : Patch*, old_blob : Blob, old_as_path : LibC::Char*, buffer : LibC::Char*, buffer_len : LibC::SizeT, buffer_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_from_buffers = git_patch_from_buffers(out : Patch*, old_buffer : Void*, old_len : LibC::SizeT, old_as_path : LibC::Char*, new_buffer : LibC::Char*, new_len : LibC::SizeT, new_as_path : LibC::Char*, opts : DiffOptions*) : LibC::Int
  fun patch_free = git_patch_free(patch : Patch)
  fun patch_get_delta = git_patch_get_delta(patch : Patch) : DiffDelta*
  fun patch_num_hunks = git_patch_num_hunks(patch : Patch) : LibC::SizeT
  fun patch_line_stats = git_patch_line_stats(total_context : LibC::SizeT*, total_additions : LibC::SizeT*, total_deletions : LibC::SizeT*, patch : Patch) : LibC::Int
  fun patch_get_hunk = git_patch_get_hunk(out : DiffHunk**, lines_in_hunk : LibC::SizeT*, patch : Patch, hunk_idx : LibC::SizeT) : LibC::Int
  fun patch_num_lines_in_hunk = git_patch_num_lines_in_hunk(patch : Patch, hunk_idx : LibC::SizeT) : LibC::Int
  fun patch_get_line_in_hunk = git_patch_get_line_in_hunk(out : DiffLine**, patch : Patch, hunk_idx : LibC::SizeT, line_of_hunk : LibC::SizeT) : LibC::Int
  fun patch_size = git_patch_size(patch : Patch, include_context : LibC::Int, include_hunk_headers : LibC::Int, include_file_headers : LibC::Int) : LibC::SizeT
  fun patch_print = git_patch_print(patch : Patch, print_cb : DiffLineCb, payload : Void*) : LibC::Int
  fun patch_to_buf = git_patch_to_buf(out : Buf*, patch : Patch) : LibC::Int
end
