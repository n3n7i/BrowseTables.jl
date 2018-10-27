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

Base.@kwdef struct TableOptions
    css_path::AbstractString = DEFAULTCSSPATH
    css_inline::Bool = true
end


# high-level API

## xDebug && print("")

function write_html_table(filename::AbstractString, tables;
                          title = "Table", caption = nothing,
                          options::TableOptions = TableOptions())
    ##
xDebug && print("write html: ");

    f = open(filename, "w")# do io
    write(f, gen_html_table([tables], title=title, caption=caption, options=options));
    close(f);
   # end

xDebug && println(" /write html");
    nothing
end

function open_html_table(table; filename = tempname() * ".html", kwargs...)
    write_html_table(filename, table; kwargs...)
    DefaultApplication.open(filename)
end


## hookstring


function gen_html_table(tables; title = "Table", caption = nothing, options = TableOptions())

  ##filename::AbstractString, 

xDebug && print("gen html: ");

  if hasmethod(schema_patch, (typeof(tables), )) 
      return gen_html_table([tables], title=title, caption=caption, options=options); 
      end;


  io = IOBuffer();

  write(io, HTMLHEADSTART)
  writetags(io -> writeescaped(io, title), io, "title")

  writestyle(io, options.css_path, options.css_inline)

  println(io, "</head>")    # close manually, opened in HTMLHEADSTART
  writetags(io, "body"; bropen = true) do io

    for table in tables

      xDebug && print(" #gen html ");


      ##@argcheck Tables.istable(table) "The table should support the interface of Tables.jl."
      println(io, "<div class='divstyle'>"); ## scroll properties attached 

      writetags(io, "table"; bropen = true) do io
                writecaption(io, caption)

                rows = table; ##rows = Tables.rows(table)

                writeschema(io, schema_patch(table)); #Tables.schema(rows))
                writetags(io, "tbody"; bropen = true) do io
                    for (id, row) in enumerate(rows)
                        writerow(io, options, merge((rowid_nXxN = RowId(id),), row)) ##obscured rowid
                        end
                    end
               end;
      println(io, "</div>"); ## endscroll
      end#for
                  
    end;
  println(io, "</html>");

xDebug && println(" /gen html ");


  return take!(io);
  end;


  ##end # module ## bottom-up simpli
  ## reverse?


# table structure

writecell(io, content::AbstractString; kind = "td", attributes = NamedTuple()) =
    writetags(io -> writeescaped(io, content), io, kind; attributes = attributes)

function writerow(io, options::TableOptions, nt::NamedTuple)

xDebug && print("row: ");

    writetags(io, "tr"; brclose = true) do io
        for x in values(nt)

xDebug && print("#r cell: ");

            htmlcontent, attributes = cellwithattributes(options, x)
            writecell(io, htmlcontent; attributes = attributes)
        end
    end

xDebug && println("/row: ");


end

writecaption(io, ::Nothing) = nothing

writecaption(io, str::AbstractString) = writetags(io -> writeescaped(io, str), io, "caption")

schema_patch(z::Array{NamedTuple{Z, T}, N}) where{Z, T, N} = Z; ##Tables.Schema(Z, Z);

schema_patch(z::Array{NamedTuple{Z}}) where{Z} = Z; ##Tables.Schema(Z, Z);


writeschema(io, ::Nothing) = nothing


function writeschema(io, sch)#::Tables.Schema)

xDebug && print("schema: ");

    writetags(io, "thead"; brclose = true) do io
        writetags(io, "tr") do io
            writecell(io, "#"; kind = "th") # row id
            foreach(x -> writecell(io, escapestring(string(x)); kind = "th"), sch)
        end
    end

xDebug && println("/schema: ");

end

function writestyle(io::IO, path::AbstractString, inline::Bool)
    if inline
        writetags(io -> write(io, read(path, String)), io, "style")
    else
        println(io, raw"<link href=\"", path, raw"\" rel=\"stylesheet\" type=\"text/css\">")
    end
    nothing
end



# cell formatting

"""
\$(SIGNATURES)
HTML representation of a cell, with attributes. Content should be escaped properly, as it is
written to HTML directly.
"""
cellwithattributes(::TableOptions, x) = escapestring(string(x)), NamedTuple()

cellwithattributes(::TableOptions, x::Real) =
    escapestring(string(x)), isfinite(x) ? NamedTuple() : (class = "nonfinite", )

cellwithattributes(::TableOptions, str::AbstractString) =
    escapestring(str), (class = "alignleft", )

cellwithattributes(::TableOptions, x::Union{Missing,Nothing}) =
    escapestring(repr(x)), (class = "likemissing", )

struct RowId
    id::Int
end

cellwithattributes(::TableOptions, rowid::RowId) =
    escapestring(string(rowid.id)), (class = "rowid", )



# low-level HTML construction

function writeescaped(io, str::AbstractString)
    for char in str
        if char == '&'
            write(io, "&amp;")
        elseif char == '<'
            write(io, "&lt;")
        elseif char == '>'
            write(io, "&gt;")
        elseif char == '"'
            write(io, "&quot;")
        else
            write(io, char)
        end
    end
    nothing
end

escapestring(str::AbstractString) = (io = IOBuffer(); writeescaped(io, str); String(take!(io)))

function writetags(f, io::IO, tag::AbstractString; bropen = false, brclose = bropen,
                   attributes = NamedTuple())

xDebug && print("tag: ");

    write(io, "<", tag)
    for (k, v) in pairs(attributes)
        write(io, " ", string(k), "=\"")
        writeescaped(io, v)
        write(io, "\"")
    end
    write(io, ">")
    bropen && println(io)
    f(io)
    write(io, "</", tag, ">")
    brclose && println(io)
    nothing
end

end # module
