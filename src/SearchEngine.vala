/***
    BEGIN LICENSE

    Copyright (C) 2013 Pedro Paredes <gangsterveggies@gmail.com>

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

using Gee;

public class SearchTool {
    public static string current_location;
    public static string original_location;
    public static string keyword;
    public static string next;
    public static string next_extension;
    public static FileType next_type;
    public static bool begin;
    public static int counter;
    public static FileEnumerator enumerator;
    public static ArrayList<string> dir_stack;

    public static Result parse_location (string loc, FileType file_type, string type, string parent) {
        string name = "";
        
        if (file_type == FileType.REGULAR) {
            int i;

            for (i = loc.length - 1; i >= 0; i--) {
                if (loc[i] == '.') {
                    i--;
                    break;
                }
            }
            
            if (i == -1) {
                i = loc.length - 1;
            }

            for (; i >= 0; i--) {
                name += loc[i].to_string ();
            }
            
            name = name.reverse ();

            return new Result (current_location + "/" + loc, name, type, parent);
        } else if (file_type == FileType.DIRECTORY) {
            return new Result (current_location + "/" + loc, loc, "Directory", parent);
        } else {
            return new Result (current_location + "/" + loc, loc, "Other", parent);
        }
    }

    public static void init_search (string _location, string _keyword) {
        dir_stack = new ArrayList<string> ();
        dir_stack.add (_location);
        begin = true;
        counter = 1;
        keyword = _keyword;
        original_location = _location;
    }

    public static Result get_next () {
        return parse_location (next, next_type, next_extension, dir_stack.first ());
    }

    public static bool has_next () {
        try {
            FileInfo file_info = null;

            if (enumerator != null && (file_info = enumerator.next_file ()) != null) {
                next = file_info.get_name ();
                next_type = file_info.get_file_type ();
                next_extension = file_info.get_content_type ();
            } else {
                if (!begin) {
                    dir_stack.remove_at(0);
                    counter--;

                    if (counter == 0) {
                        return false;
                    }
                }

                begin = false;
                var directory = File.new_for_path (dir_stack.first ());
                enumerator = directory.enumerate_children ("standard::*", 0);
                current_location = dir_stack.first ();

                while ((file_info = enumerator.next_file ()) == null) {
                    dir_stack.remove_at (0);
                    counter--;

                    if (counter == 0) {
                        return false;
                    }

                    directory = File.new_for_path (dir_stack.first ());
                    enumerator = directory.enumerate_children ("standard::*", 0);
                    current_location = dir_stack.first ();
                }

                next = file_info.get_name ();
                next_type = file_info.get_file_type ();
                next_extension = file_info.get_content_type ();
            }
        } catch (Error e) {
            stderr.printf ("File Error trying to read a directory: %s\n", e.message);
        }

        if (next_type == FileType.DIRECTORY) {
            dir_stack.add (current_location + "/" + next);
            counter++;
        }

        if ((keyword.length > next.length || !(keyword.down () in next.down ())) && keyword != "*") {
            return has_next ();
        }

        return true;
    }
}