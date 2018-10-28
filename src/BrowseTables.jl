
module xBrowseTables

##export write_html_table, open_html_table, TableOptions
##using ArgCheck: @argcheck
##import DefaultApplication
##using DocStringExtensions: SIGNATURES
##import Tables


# options and customizations

const HTMLHEADSTART = """
<!DOCTYPE html><html lang="en"><head>
  <meta content="text/html; charset=utf-8" http-equiv="Content-Type">
  <meta content="width=device-width, initial-scale=1, shrink-to-fit=no" name="viewport">
"""

const DEFAULTCSSPATH = abspath(@__DIR__, "..", "assets", "BrowseTables.css")
const DEFAULTCSSDIR = abspath(@__DIR__, "..", "assets")

const CssDir = DEFAULTCSSDIR
const xDebug = true

struct RowId
  id::Int
  end

const tdef = Dict([String => (class = "alignleft", ), Missing => (class = "likemissing", ), Nothing => (class = "likemissing", ), 
					RowId => (class = "rowid", )]);

Base.@kwdef struct xTableOptions
  css_path::AbstractString = DEFAULTCSSPATH
  css_inline::Bool = true
  d::Dict = Dict(["td" => tdef]);
end

Base.show(io::IO, x::RowId) = write(io, "$(x.id)");


function gen_html_table(tables; title = "Table", caption = nothing, options = xTableOptions())

  if hasmethod(schema_patch, (typeof(tables), )) 
    return gen_html_table([tables], title=title, caption=caption, options=options); 
    end;
	
  io = IOBuffer();
  write(io, HTMLHEADSTART)
  
  writecell(io, title, kind="title");
  writestyle(io, options.css_path, options.css_inline)
  println(io, "</head>")    # close manually, opened in HTMLHEADSTART
	
  writetags(io, "body") #do io
  for table in tables

    ##@argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
    println(io, "<div class='divstyle'>"); ## scroll properties attached 

    writetags(io, "table") #do io
    writecaption(io, caption)

    rows = table;
    writeschema(io, schema_patch(table)); #Tables.schema(rows))
				
    writetags(io, "tbody") #do io
    for (id, row) in enumerate(rows)
	writerow(io, options, merge((rowid_nXxN = RowId(id),), row)) ##obscured rowid
	end

    println(io, "</tbody></table></div>"); ## endscroll
    end#for
  println(io, "</body></html>");  
  return String(take!(io));
  end;

writecaption(io, ::Nothing) = nothing

writecaption(io, str::AbstractString) = writecell(io, str, kind="caption");

schema_patch(z::Array{NamedTuple{Z, T}, N}) where{Z, T, N} = Z; 

schema_patch(z::Array{NamedTuple{Z}}) where{Z} = Z; 
  
function writestyle(io::IO, path::AbstractString, inline::Bool)
  if inline
    writecell(io, read(path, String); kind="style");	
    else
    writetags(io, "link", attributes = (href = "$path", rel="stylesheet", type="text/css"));
    end
  nothing
  end

function writeschema(io, sch)#::Tables.Schema)
  writetags(io, "thead");
  writetags(io, "tr"); 
  writecell(io, "#"; kind = "th") # row id	
  foreach(x -> writecell(io, "$x"; kind = "th"), sch) 	
  writetags(io, "/tr></thead"); ## do io        
  end


function cellwithattributes(setting::xTableOptions, kind, content)
  pretty = IOBuffer();
  show(pretty, content);
  xcont = String(take!(pretty));
    
  if(haskey(setting.d, kind) && haskey(setting.d[kind], typeof(content)))
    return xcont, setting.d[kind][typeof(content)];
    end;	
				
  return xcont, NamedTuple()
  end;
      

# table structure

function writerow(io, options::xTableOptions, nt)

  writetags(io, "tr") #do io
  for x in values(nt)
    htmlcontent, attributes = cellwithattributes(options, "td", x)
    writecell(io, htmlcontent, attributes = attributes)
    end
  end;


function writecell(io, content::AbstractString; kind = "td", attributes = NamedTuple(), singletons = [])

  writetags( io, kind; attributes = attributes, singletons = [])
  write(io, "$content");
  writetags( io, "/$kind");
  nothing
  end;
	
# low level api

function writetags(io::IO, tag::AbstractString; attributes = NamedTuple(), singletons = [])
  write(io, "<", tag)
  for (k, v) in pairs(attributes)
    write(io, " $k = \"$v\" ")
    end
  for k in singletons
    write(io, " $k ")
    end
  write(io, ">")
  nothing
  end

end # module
