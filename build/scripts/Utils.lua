function cat(file)
  local file = assert(io.open(file, "r"))
  local output = file:read('*all')
  file:close()
  return output
end

function execute(cmd)
  print(cmd)
  local file = assert(io.popen(cmd, "r"))
  local output = file:read('*all')
  file:close()
  return output
end

local git = {}

function git.clone(dir, url, target)
  local cmd = "git clone " .. url .. " " .. path.translate(dir) 
  if target ~= nil then
    cmd = cmd .. " " .. target
  end
  execute(cmd)
end

function git.checkout(dir, rev)
  local cmd = "git -C " .. path.translate(dir) .. " checkout " .. rev
  execute(cmd)
end

function git.revision(dir)
  local cmd = "git -C " .. path.translate(dir) .. " checkout " .. rev
  execute(cmd)
end

function http.progress (total, curr)
  local ratio = curr / total;
  ratio = math.floor(math.min(math.max(ratio, 0), 1));

  local percent = ratio * 100;
  print("Download progress (" .. percent .. "%/100%)")
end

function download(url, file)
  print("Downloading file " .. file)
  local res = http.download(url, file, http.progress)

  if res == nil then
    error("Error downloading file " .. file)
  end
end

--
-- Allows copying directories.
-- It uses the premake patterns (**=recursive match, *=file match)
-- NOTE: It won't copy empty directories!
-- Example: we have a file: src/test.h
--  os.copydir("src", "include") simple copy, makes include/test.h
--  os.copydir("src", "include", "*.h") makes include/test.h
--  os.copydir(".", "include", "src/*.h") makes include/src/test.h
--  os.copydir(".", "include", "**.h") makes include/src/test.h
--  os.copydir(".", "include", "**.h", true) will force it to include dir, makes include/test.h
--
-- @param src_dir
--    Source directory, which will be copied to dst_dir.
-- @param dst_dir
--    Destination directory.
-- @param filter
--    Optional, defaults to "**". Only filter matches will be copied. It can contain **(recursive) and *(filename).
-- @param single_dst_dir
--    Optional, defaults to false. Allows putting all files to dst_dir without subdirectories.
--    Only useful with recursive (**) filter.
-- @returns
--    True if successful, otherwise nil.
--
function os.copydir(src_dir, dst_dir, filter, single_dst_dir)
  filter = filter or "**"
  src_dir = src_dir .. "/"
  print('copy "' .. path.getabsolute(src_dir) .. filter .. '" to "' .. dst_dir .. '".')
  if not os.isdir(src_dir) then error(src_dir .. " is not an existing directory!") end
  dst_dir = dst_dir .. "/"
  local dir = path.rebase(".",path.getabsolute("."), src_dir) -- root dir, relative from src_dir
 
  os.chdir( src_dir ) -- change current directory to src_dir
    local matches = os.matchfiles(filter)
  os.chdir( dir ) -- change current directory back to root
 
  local counter = 0
  for k, v in ipairs(matches) do
    local target = iif(single_dst_dir, path.getname(v), v)
    --make sure, that directory exists or os.copyfile() fails
    os.mkdir( path.getdirectory(dst_dir .. target))
    if os.copyfile( src_dir .. v, dst_dir .. target) then
      counter = counter + 1
    end
  end
 
  if counter == #matches then
    print( counter .. " files copied.")
    return true
  else
    print( "Error: " .. counter .. "/" .. #matches .. " files copied.")
    return nil
  end
end

--
-- Allows removing files from directories.
-- It uses the premake patterns (**=recursive match, *=file match)
--
-- @param src_dir
--    Source directory, which will be copied to dst_dir.
-- @param filter
--    Optional, defaults to "**". Only filter matches will be copied. It can contain **(recursive) and *(filename).
-- @returns
--    True if successful, otherwise nil.
--
function os.rmfiles(src_dir, filter)
  filter = filter or "**"
  src_dir = src_dir .. "/"
  print('rm "' .. path.getabsolute(src_dir) .. filter)
  if not os.isdir(src_dir) then error(src_dir .. " is not an existing directory!") end
  local dir = path.rebase(".",path.getabsolute("."), src_dir) -- root dir, relative from src_dir
 
  os.chdir( src_dir ) -- change current directory to src_dir
    local matches = os.matchfiles(filter)
  os.chdir( dir ) -- change current directory back to root
 
  local counter = 0
  for k, v in ipairs(matches) do
    if os.remove( src_dir .. v) then
      counter = counter + 1
    end
  end
 
  if counter == #matches then
    print( counter .. " files removed.")
    return true
  else
    print( "Error: " .. counter .. "/" .. #matches .. " files removed.")
    return nil
  end
end