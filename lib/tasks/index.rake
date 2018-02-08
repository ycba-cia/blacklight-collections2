require 'rubygems'
require 'rsolr'
require 'rexml/document'
require 'marc'

include REXML

namespace :index do
  desc "Copy index from CCD Solr to Blacklight Solr"
  task copy: :environment do

    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    start=0
    stop=false
    solr = RSolr.connect :url => 'http://127.0.0.1:8380/solr/biblio' #make sure tunnelling prod!
    #solr = RSolr.connect :url => 'http://discoverdev.odai.yale.edu/vufind-solr/biblio'
    target_solr = RSolr.connect :url => SOLR_CONFIG['url']

    while stop!=true
      # send a request to /select
      response = solr.post 'select', :params => {
          :q=>'institution:"Yale Center for British Art"',
          #:q=>'recordID:120',
          :sort=>'id asc',
          :start=>start,
          :rows=>100
      }
      documents = Array.new

      stop = true if response['response']['docs'].length == 0

      response["response"]["docs"].each{|doc|

        doc.delete("title_fullStr")
        doc.delete("callnumber_txt")
        doc.delete("author_additionalStr")
        spell=doc.delete("spelling")
        doc["spell"] = spell if spell
        if doc["type_standard"] and doc["type_parent"]
          doc["type_facet"][0]=doc["type_parent"][0]
          doc["type_facet"][1]=doc["type_parent"][0]+":"+doc["type_standard"][0]
        end
        docClone=doc.clone

        if doc['fullrecord']
          if doc['recordtype'] == "lido"
            xml = REXML::Document.new(doc['fullrecord'])
            #puts xml
            ort = REXML::XPath.first(xml, '//lido:rightsWorkSet/lido:rightsType/lido:conceptID[@lido:type="object copyright"]')
            rightsURL = REXML::XPath.first(xml, '//lido:legalBodyID[@lido:type="URL"]')
            ort = ort.text if ort
            rightsURL = rightsURL.text if rightsURL

            videos = []
            videoURL = REXML::XPath.each(xml, '//lido:linkResource[@lido:formatResource="video"]') { |video|
              videos.append(video.text)
            }

            #issue 30 test solution, commenting out in favor of xslt change
            #actorInRole = []
            #REXML::XPath.each(xml, '//lido:eventActor/lido:displayActorInRole') { |actor|
            #  actorInRole.append(actor.text)
            #}

            citations = []
            REXML::XPath.each(xml, '//lido:relatedWorkSet/lido:relatedWork/lido:displayObject') { |citation|
              close = false
              citation = citation.text.gsub('/') { |match|
                  value = close ? '</i>' : '<i>'
                  close = !close
                  value
              } if citation.text
              citations.append(citation)
            }

            cur_comm = []
            c1 = REXML::XPath.each(xml, '//lido:eventSet/lido:displayEvent[../lido:event/lido:eventType/lido:term="Curatorial comment"]/text()') { |cc|
              cur_comm.append(cc)
            }

            cur_comm_author = []
            REXML::XPath.each(xml, '//lido:eventSet/lido:event/lido:eventActor/lido:actorInRole/lido:actor/lido:nameActorSet/lido:appellationValue[../../../../../lido:eventType/lido:term="Curatorial comment"]/text()') { |cc_auth|
              cur_comm_author.append(cc_auth)
            }

            cur_comm_date = []
            REXML::XPath.each(xml,'//lido:eventSet/lido:event/lido:eventDate/lido:displayDate[../../lido:eventType/lido:term="Curatorial comment"]/text()') { |cc_date|
              cur_comm_date.append(cc_date)
            }

            #doc['curatorial_comment_txt'] = cur_comm.to_s if cur_comm
            #doc['curatorial_comment_auth_ss'] = cur_comm_author.to_s if cur_comm_author
            #doc['curatorial_comment_date_ss'] = cur_comm_date.to_s if cur_comm_date

            cur_comm.each { |cc|
              doc['curatorial_comment_txt'] = cc.to_s
            }
            cur_comm_author.each { |cc|
              doc['curatorial_comment_auth_ss'] = cc.to_s
            }
            cur_comm_date.each { |cc|
              doc['curatorial_comment_date_ss'] = cc.to_s
            }

            #puts "CC1:" + doc['curatorial_comment_txt'].to_s
            #puts "CC2:" + doc['curatorial_comment_auth_ss'].to_s
            #puts "CC3:" + doc['curatorial_comment_date_ss'].to_s

            doc['ort_ss'] = ort
            doc['rightsURL_ss'] = rightsURL
            doc['videoURL_ss'] = videos
            doc['citation'] = citations
            #issue 30 test solution, commenting out actorInRole_ss in favor of xslt change
            #doc['actorInRole_ss'] = actorInRole
            #puts "CC4:" + doc['rightsURL_ss'].to_s

          elsif doc['recordtype'] == 'marc'
            doc['isbn_ss'] = get_isbn(doc)
          end
        end

        int_fields = ["earliestDate","latestDate","physical_heightValue","physical_widthValue"]
        docClone.each do |key, array|
          if key!="id" and !key.end_with?("_facet")
            value=doc.delete(key)
            doc[key+"_ss"] = value if value and key != 'fullrecord'
            doc[key+"_txt"] = value if value
            if int_fields.include? key
              doc[key+"_is"] = value.map(&:to_i) if value && value.is_a?(Array)
              doc[key+"_i"] = value.to_i if value && value.is_a?(String)
            end
          end
        end

        doc['ts_s'] = Time.now

        puts "doc:" + doc["id"]
        documents.push(doc)

      }
      puts "page:"+start.to_s
      puts "len:" + documents.length.to_s
      target_solr.add documents
      target_solr.commit
      start +=100
      sleep(1)  #be kind to others :)
    end
    target_solr.optimize
  end

  desc 'Clear the index.  Deletes all documents in the index'
  task clear: :environment do
    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    solr = RSolr.connect :url => SOLR_CONFIG['url']
    solr.delete_by_query "id:*"
    solr.commit
    solr.optimize
  end

  desc "Extract ISBN from MARC and add to index"
  task add_isbn: :environment do
    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    solr_url = SOLR_CONFIG['url']
    solr = RSolr.connect :url => solr_url
    stop = false
    start = 0
    while !stop
      response = solr.post 'select', :params => {
          :fq=>'recordtype_ss:marc',
          #:fq=>'recordtype_ss:marc && id:2038446',
          :fl=> 'recordtype_ss,id,fullrecord_txt',
          :sort=>'id asc',
          :start=>start,
          :rows=>100
      }
      docs_returned = response['response']['docs'].length
      stop = true if docs_returned == 0
      start += docs_returned
      response["response"]["docs"].each do |doc|
        id = doc['id']
        marc = get_marc(doc)
        isbn = get_isbn(marc)
        form_genre = get_form_genre(marc)
        marc_contents = get_marc_field(marc, '505', 'a')
        Rails.logger.info "#{id} : #{isbn} : #{form_genre}"
        json = JSON.unparse([
                                 { 'id' => id,
                                   'isbn_ss' => { 'set' => isbn },
                                   'form_genre_ss' => { 'set' => form_genre },
                                   'marc_contents_txt' => { 'set' => marc_contents}
                                 }
                             ])
        #puts "JSON: #{json}"
        solr.update data: json, headers: { 'Content-Type' => 'application/json' } if isbn or form_genre or marc_contents
      end
      solr.commit
      sleep(0.3)
    end

  end

  desc "TODO"
  task add_iiif: :environment do
  end



  desc "Export TSV"
  task export_tsv: :environment do
    SOLR_CONFIG = Rails.application.config_for(:blacklight)
    solr_url = SOLR_CONFIG['url']
    solr = RSolr.connect :url => solr_url
    stop = false
    start = 0
    CatalogController.new
    fields = []
    fields.push({ :key => 'id', :label => 'ID' })
    fields.push({ :key => 'recordID_ss', :label => 'recordID'})
    fields.push({ :key =>  'author_ss', :label => 'Creator'  })
    fields.push({ :key =>  'author_additional_ss', :label => 'Contributors' })  # Bibliographic
    fields.push({ :key =>  'title_alt_txt', :label => 'Alternate Title(s)' })
    fields.push({ :key =>  'publishDate_txt', :label => 'Date' })
    fields.push({ :key =>  'format_txt', :label => 'Medium' })
    fields.push({ :key =>  'physical_txt', :label => 'Dimensions' })
    fields.push({ :key =>  'type_ss', :label => 'Classification' }) #Bibliographic
    fields.push({ :key =>  'publisher_ss', :label => 'Imprint' }) #Bibliographic
    fields.push({ :key =>  'description_txt', :label => 'Inscription(s)/Marks/Lettering'  })
    fields.push({ :key =>  'credit_line_txt', :label => 'Credit Line' })
    fields.push({ :key =>  'isbn_ss', :label => 'ISBN' })  #Bibliographic
    fields.push({ :key =>  'callnumber_txt', :label => 'Accession Number' })
    fields.push({ :key =>  'collection_txt', :label => 'Collection' })
    fields.push({ :key =>  'geographic_culture_txt', :label => 'Culture' })
    fields.push({ :key =>  'era_txt', :label => 'Era' })
    fields.push({ :key =>  'url_txt', :label => 'Link', helper_method: 'render_as_link' })
    fields.push({ :key =>  'topic_subjectActor_ss', :label => 'People Represented or Subject'})
    fields.push({ :key =>  'topic_ss', label: 'Subject Terms'  })
    fields.push({ :key =>  'citation_txt', :label => 'Publications' })
    #fields.push({ :key =>  'resourceURL_ss', :label => 'Thumbnail'})
    fields.push({ :key =>  'videoURL_ss', :label => 'Video' })
    headers = []
    fields.each {|f|
      headers.push(f[:label])
    }
    puts headers.join("\t")
    while !stop
      response = solr.post 'select', :params => {
          :fq=>'+auth_author_ss:"Joseph Mallord William Turner" +collection_ss:"Prints and Drawings" +typeTxt_ss:"Print"',
          :fl=> '*',
          :sort=>'id asc',
          :start=>start,
          :rows=>100
      }
      docs_returned = response['response']['docs'].length
      stop = true if docs_returned == 0
      start += docs_returned
      response["response"]["docs"].each do |doc|
        result = []
        fields.each { |f|
          values = doc[f[:key]]
          data = ""
          if values.is_a?(Array) and values.length > 0
            data = values.join(', ')
          elsif values.is_a?(String)
            data = values
          end
          result.push(data)
        }
        puts result.join("\t")
      end
    end
  end

  def get_marc(doc)
    marc = doc['fullrecord_txt'][0]
    marc.gsub!('#31;', "\x1F")
    marc.gsub!('#30;', "\x1E")
    MARC::Reader.decode(marc)
  end

  def get_isbn(marc)
    isbn = nil
    if marc['020']
      marc.each_by_tag('020') { |tag|
        current_isbn = tag['a'] || ''
        current_isbn = current_isbn[/[0-9]+/]
        if current_isbn and current_isbn.length == 10
          isbn = current_isbn
        end
      }
    end
    return isbn
  end

  def get_marc_field(marc, field, subfield)
    values = []
    if marc[field]
      marc.each_by_tag(field) { |tag|
        values.push(tag[subfield])
      }
    end
    values.empty? ? nil : values
  end

  def get_form_genre(marc)
    field = '655'
    subfield = ['a','x','z','y']
    values = []
    if marc[field]
      marc.each_by_tag(field) { |tag|
        each_values = []
        subfield.each { |sf|
          each_values.push(tag[sf]) if tag[sf].nil? == false
        }
        values.push(each_values.join(" -- "))
      }
    end
    values.empty? ? nil : values
  end
end
