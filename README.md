# Semdoc::Alps

Semantic Document for ALPS

## Installation

Add this line to your application's Gemfile:

    gem 'semdoc-alps'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install semdoc-alps

## Usage

TODO: Write usage instructions here

## Example

    # Load local file & apply local profile
    doc = Semdoc::Alps::Document.load('file:///Users/tkawa/Projects/alps-sample/public/status.json')
    doc.apply_profile('file:///Users/tkawa/Projects/alps-sample/public/status-alps.json')
    postings = doc.items_for("http://alps.io/schema.org/BlogPosting#BlogPosting")
    texts = doc.items_for('text')
    users = doc.items_for('http://alps.io/schema.org/Person#Person')
    
    doc = Semdoc::Alps::Document.load('file:///Users/tkawa/Projects/alps-sample/public/timeline.json')
    doc.apply_profile('file:///Users/tkawa/Projects/alps-sample/public/status-alps.json')
    
    doc = Semdoc::Alps::Document.load('http://localhost:3000/timeline.json')
    doc.apply_profile('http://localhost:3000/status-alps.json')
    
    doc = Semdoc::Alps::Document.load('https://api.github.com/users/tkawa/followers')
    doc.apply_profile('http://localhost:3000/github-user-alps.json')
    users = doc.items_for("http://alps.io/schema.org/Person#Person")
    u1_doc = users.first.link_for("http://alps.io/iana/relations#self")
    u1 = u1_doc.item_for("http://alps.io/schema.org/Person#Person")

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
