<!DOCTYPE html>
<html>
<head>
    <title>${ENVIRONMENT} Blog</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
</head>
<body>
    <h1>${ENVIRONMENT} Blog</h1>

    <form id="new-post">
        <input id="title" type="text" placeholder="Title" required>
        <input id="content" type="text" placeholder="Content" required>
        <button type="submit">Create</button>
    </form>

    <div id="posts"></div>

    <script>
        const API_ENDPOINT = '${API_ENDPOINT}';

        let lastPostId = null;

        function getPosts() {
            $.get(API_ENDPOINT + '/posts', function(data) {
                $('#posts').html('');
                data.forEach(function(post) {
                    lastPostId = post._id.$oid;
                    const body = JSON.parse(post.body);
                    $('#posts').append(`<h2>$${body.title}</h2><p>$${body.content}</p>`);
                });
                $('#posts').prepend('<p>Last Post ID: ' + lastPostId + '</p>');
            });
        }

        $(document).ready(function() {
            getPosts();

            $('#new-post').on('submit', function(e) {
                e.preventDefault();

                const post = {
                    title: $('#title').val(),
                    content: $('#content').val()
                };

                $.ajax({
                  type: 'POST',
                  url: `${API_ENDPOINT}/posts`,
                  data: JSON.stringify({ body: JSON.stringify(post) }),
                  contentType: 'application/json',
                  success: function (data) {
                    $('#title').val('');
                    $('#content').val('');
                    getPosts();
                  },
                  error: function (jqXHR, textStatus, errorThrown) {
                    console.log(jqXHR);
                    console.log(textStatus);
                    console.log(errorThrown);
                    alert('Error creating post');
                  }
                });
            });
        });
    </script>
</body>
</html>