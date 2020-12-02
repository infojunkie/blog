Jekyll::Hooks.register :documents, :post_render do |doc|
  if doc.output_ext == ".html"
    doc.output =
      doc.output.gsub(
        /<h([1-6])(.*?)id="([\w-]+)"(.*?)>(.*?)<\/h[1-6]>/,
        '<h\1\2id="\3"\4><a class="header" href="#\3">\5</a></h\1>'
      )
  end
end
