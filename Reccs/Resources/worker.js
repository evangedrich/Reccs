/**
 * Cloudflare Worker for serving movie data from D1
 * 
 * This worker queries your existing D1 database and transforms the data
 * to match the iOS app's MovieEntry structure.
 * 
 * Deploy this with: wrangler deploy
 */

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        }
      });
    }
    
    // Get all movies (CFF, GFF, CSF only)
    if (url.pathname === '/api/movies') {
      try {
        const { results } = await env.DB.prepare(`
          SELECT * FROM reccs 
          WHERE SUBSTR(id, 5, 3) IN ('CFF', 'GFF', 'CSF')
          ORDER BY year DESC
        `).all();
        
        const movies = results.map(rowToMovie);
        
        return new Response(JSON.stringify(movies), {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=3600' // Cache for 1 hour
          }
        });
      } catch (error) {
        console.error('Error fetching movies:', error);
        return new Response(JSON.stringify({ 
          error: error.message,
          stack: error.stack 
        }), {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
    }
    
    // Get single movie by ID
    const movieIdMatch = url.pathname.match(/^\/api\/movies\/(.+)$/);
    if (movieIdMatch) {
      const movieId = movieIdMatch[1];
      
      // Validate that this is a movie ID (has CFF, GFF, or CSF)
      const category = movieId.substring(4, 7);
      if (!['CFF', 'GFF', 'CSF'].includes(category)) {
        return new Response(JSON.stringify({ 
          error: 'Invalid movie ID category. Expected CFF, GFF, or CSF.' 
        }), {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
      
      try {
        const { results } = await env.DB.prepare(
          'SELECT * FROM reccs WHERE id = ?'
        ).bind(movieId).all();
        
        if (results.length > 0) {
          const movie = rowToMovie(results[0]);
          
          return new Response(JSON.stringify(movie), {
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Cache-Control': 'public, max-age=3600'
            }
          });
        } else {
          return new Response(JSON.stringify({ 
            error: 'Movie not found' 
          }), {
            status: 404,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            }
          });
        }
      } catch (error) {
        console.error('Error fetching movie:', error);
        return new Response(JSON.stringify({ 
          error: error.message 
        }), {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        });
      }
    }
    
    return new Response('Not found', { status: 404 });
  }
};

/**
 * Helper function to safely parse JSON
 */
function parseJson(s) {
  if (s == null) return undefined;
  try {
    return JSON.parse(s);
  } catch (e) {
    console.error('JSON parse error:', e, 'Input:', s);
    return undefined;
  }
}

/**
 * Transform a D1 row to match the iOS MovieEntry structure
 * Maps from your D1 schema to the JSON format used by the iOS app
 */
function rowToMovie(row) {
  // Build the title object
  const title = { original: row.title_original };
  if (row.title_transliteration) title.transliteration = row.title_transliteration;
  if (row.title_translation) title.translation = row.title_translation;
  
  // Build the group object
  const group = { language: row.group_language };
  if (row.group_people) group.people = row.group_people;
  if (row.group_country) group.country = row.group_country;
  if (row.group_location) group.location = row.group_location;
  // Note: group_religion is in D1 but not in MovieEntry, so we omit it
  
  // Build the location object
  const location = {
    x: row.coord_lng || 0,
    y: row.coord_lat || 0,
    name: row.coord_name || ''
  };
  
  // Parse the info field (it's stored as JSON array in D1)
  // The iOS app expects a single string, so we join the array
  const infoParsed = parseJson(row.info);
  const info = Array.isArray(infoParsed) ? infoParsed.join('\n\n') : (row.info || '');
  
  // Build the movie object
  const movie = {
    id: row.id,
    title: title,
    year: row.year?.toString() || '',
    runtime: row.runtime || 0,
    genre: parseJson(row.genre) || [],
    tags: parseJson(row.tags) || [],
    group: group,
    info: info,
    watch: parseJson(row.watch_urls) || [],
    trailer: row.trailer_url || '',
    color: row.color || '#000000',
    location: location
  };
  
  return movie;
}
