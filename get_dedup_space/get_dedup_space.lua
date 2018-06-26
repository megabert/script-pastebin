#!/usr/bin/env lua

-- input data format (this script expects the data from stdin)
--
-- INODE_NR
-- FILE_SIZE
-- LINK_COUNT
--
-- generated with: 
--
-- find . ! -links 1 -type f -printf "%i %s %n\n" >files.txt 2>/dev/null &
--
function format_number(nr)

	nr=tostring(nr)
	local res=""
	local nr_len = nr:len()
	local z=0
	local comma
	
	for i=0,nr_len-1,1 do
		z=z+1
		cur=nr:sub(nr_len-i,nr_len-i)
		if(comma ) then
			res=comma..res
		end
		res=nr:sub(nr_len-i,nr_len-i)..res
		if (z==3) then
			comma=","
			z=0
		else
			comma=nil
		end
	end
	return res

end

function process() 

	local line			= io.stdin:read("*l")
	local inode_link_count		= {}
	local files_with_duplicates	= 0
	local duplicate_files		= 0
	local saved_space		= 0
	local inode
	local size
	local processed_files		= 0

	repeat

		inode,size = line:match("(%d+)%s+(%d+)%s+%d+")
		if(inode) then
			inode_link_count[inode] = (inode_link_count[inode] or 0) + 1
			processed_files=processed_files+1
			if(inode_link_count[inode]>1) then
				if(inode_link_count[inode]==2) then
					files_with_duplicates=files_with_duplicates+1
					duplicate_files=duplicate_files+1	-- add a counter for the so far not counted single file
				end
				duplicate_files=duplicate_files+1
				saved_space=saved_space+tonumber(size)
			end
		end
		line	= io.stdin:read("*l")
	until not line

	return processed_files,files_with_duplicates, duplicate_files, saved_space

end

function present_data(processed_files,files_with_duplicates, duplicate_files, saved_space) 


	print(string.format("Processed files:                %18s",format_number(processed_files)))
	print(string.format("Files with duplicates:          %18s",format_number(files_with_duplicates)))
	print(string.format("Duplicate files:                %18s",format_number(duplicate_files)))
	print(string.format("Saved Space due to hardlinking: %18s",format_number(saved_space)))


end
present_data(process())


