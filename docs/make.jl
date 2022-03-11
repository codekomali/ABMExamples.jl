using ABMExamples
using Documenter

DocMeta.setdocmeta!(ABMExamples, :DocTestSetup, :(using ABMExamples); recursive=true)

makedocs(;
    modules=[ABMExamples],
    authors="Code Komali <code.komali@gmail.com> and contributors",
    repo="https://github.com/codekomali/ABMExamples.jl/blob/{commit}{path}#{line}",
    sitename="ABMExamples.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://codekomali.github.io/ABMExamples.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/codekomali/ABMExamples.jl",
    devbranch="master",
)
