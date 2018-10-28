
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

Base.show(io::IO, x::RowId) = write(io, "$(x.id)");


const tdef = Dict([String => (class = "alignleft", ), Missing => (class = "likemissing", ), Nothing => (class = "likemissing", ), 
					RowId => (class = "rowid", )]);

Base.@kwdef struct xTableOptions
    css_path::AbstractString = DEFAULTCSSPATH
    css_inline::Bool = true
	d::Dict = Dict(["td" => tdef]);
end



function gen_html_table(tables; title = "Table", caption = nothing, options = xTableOptions())

  ##filename::AbstractString, 

xDebug && print("gen html: ");

  if hasmethod(schema_patch, (typeof(tables), )) 
      return gen_html_table([tables], title=title, caption=caption, options=options); 
      end;


  io = IOBuffer();

  write(io, HTMLHEADSTART)
  
  #writetags(io -> writeescaped(io, title), io, "title")
  
  writecell(io, title, kind="title");

  writestyle(io, options.css_path, options.css_inline)

  println(io, "</head>")    # close manually, opened in HTMLHEADSTART
  writetags(io, "body") #do io

    for table in tables

      xDebug && print(" #gen html ");


      ##@argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
      println(io, "<div class='divstyle'>"); ## scroll properties attached 

      writetags(io, "table") #do io
                writecaption(io, caption)

                rows = table; ##rows = Tables.rows(table)

                writeschema(io, schema_patch(table)); #Tables.schema(rows))
				
                writetags(io, "tbody") #do io
                    for (id, row) in enumerate(rows)
                        writerow(io, options, merge((rowid_nXxN = RowId(id),), row)) ##obscured rowid
                        end
                    #end
               #end;
      println(io, "</div>"); ## endscroll
      end#for
                  
    #end;
  println(io, "</html>");

xDebug && println(" /gen html ");

  
  ##reesc = String(take!(io));
  
  ##print(io, reesc);
  
  return String(take!(io));
  end;

##function writerow(io, options::xTableOptions, nt::NamedTuple)  
  
  
writecaption(io, ::Nothing) = nothing

#writecaption(io, str::AbstractString) = writetags(io -> writeescaped(io, str), io, "caption")

writecaption(io, str::AbstractString) = writecell(io, str, kind="caption")

schema_patch(z::Array{NamedTuple{Z, T}, N}) where{Z, T, N} = Z; ##Tables.Schema(Z, Z);

schema_patch(z::Array{NamedTuple{Z}}) where{Z} = Z; ##Tables.Schema(Z, Z);


  
##function writecell(io, content::AbstractString; kind = "td", attributes = NamedTuple(), singletons = [])
##function writetags(io::IO, tag::AbstractString; attributes = NamedTuple(), singletons = [])
  
  function writestyle(io::IO, path::AbstractString, inline::Bool)
    if inline
        ##writetags(io -> write(io, read(path, String)), io, "style")
		writecell(io, read(path, String); kind="style");
		
    else
	    writetags(io, "link", attributes = (href = "$path", rel="stylesheet", type="text/css"));
        #println(io, raw"<link href=\"", path, raw"\" rel=\"stylesheet\" type=\"text/css\">")
    end
    nothing
end

function writeschema(io, sch)#::Tables.Schema)

xDebug && print("schema: ");

    writetags(io, "thead"); ##; brclose = true) do io
	writetags(io, "tr"); ## do io
	writecell(io, "#"; kind = "th") # row id
	
    foreach(x -> writecell(io, "$x"; kind = "th"), sch) ##escapestring(string(x))
	
	writetags(io, "/tr></thead"); ## do io
        #end
    end


function cellwithattributes(setting::xTableOptions, kind, content)
  pretty = IOBuffer();
  show(pretty, content);
  xcont = String(take!(pretty));
  
  xDebug && begin
    println();
	print(typeof(content), "  ");
    print(haskey(setting.d, kind), " ", haskey(setting.d[kind], typeof(content)), ": ");
	end;
  
  if(haskey(setting.d, kind) && haskey(setting.d[kind], typeof(content)))
    return xcont, setting.d[kind][typeof(content)];
	end;	
  return xcont, NamedTuple()
  end;
      

# table structure

function writerow(io, options::xTableOptions, nt)

xDebug && print("row: ");

    writetags(io, "tr") #do io
        for x in values(nt)

xDebug && print("#r cell: ");

            htmlcontent, attributes = cellwithattributes(options, "td", x)
            writecell(io, htmlcontent, attributes = attributes)
            end
        #end

    end;


function writecell(io, content::AbstractString; kind = "td", attributes = NamedTuple(), singletons = [])

    writetags( io, kind; attributes = attributes, singletons = [])
	write(io, "$content");
	writetags( io, "/$kind");
	nothing
	end;
	

# low level api


function writetags(io::IO, tag::AbstractString; attributes = NamedTuple(), singletons = [])

xDebug && print("tag: ");

    write(io, "<", tag)
    for (k, v) in pairs(attributes)
        write(io, " $k = \"$v\" ")
        #writeescaped(io, v)
        #write(io, "\"")
    end
	for k in singletons
        write(io, " $k ")
    end
    write(io, ">")
#    bropen && println(io)
#    f(io)
#    write(io, "</", tag, ">")
#    brclose && println(io)
    nothing
end

end # module
