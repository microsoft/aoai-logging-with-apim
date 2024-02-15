// Copyright (c) Microsoft. All rights reserved.

namespace LogParser.Services;

/// <summary>
/// TikToken Service
/// </summary>
public class TikTokenService
{
    HttpClient client = new();
    TikToken tikToken = TikToken.EncodingForModel("gpt-3.5-turbo");

    /// <summary>
    /// Count the number of tokens for the input
    /// </summary>
    /// <param name="input">TikTokenService</param>
    /// <returns>Token count</returns>
    public async Task<int> CountToken(List<Message> messages)
    {
        int total = 0;
        foreach(Message message in messages) 
        {
            if (message.Content is string)
            {
                total += tikToken.Encode(message.Content).Count;
            }
            else if (message.Content is JArray)
            {
                List<VisionContent> contents = 
                    JsonConvert.DeserializeObject<List<VisionContent>>(message.Content.ToString());

                foreach(VisionContent content in contents)
                {
                    if (!string.IsNullOrEmpty(content.Text))
                    { 
                        total += tikToken.Encode(content.Text).Count;
                    }
                    else
                    {
                        if (content.ImageUrl is null)
                        {
                            continue; 
                        }
                        if (content.ImageUrl.Details == "low")
                        {
                            total += 85;
                        }
                        else if (content.ImageUrl.Url.StartsWith("data"))
                        {
                            string base64Image = content.ImageUrl.Url.Split(",")[1];
                            byte[] imageBytes = Convert.FromBase64String(base64Image);
                            MemoryStream stream = new(imageBytes);
                            Image img = await Image.LoadAsync(stream);
                            total += CalculateFromImage(img);
                        }
                        else
                        {
                            Stream imageStream = await client.GetStreamAsync(content.ImageUrl.Url);
                            Image img = await Image.LoadAsync(imageStream);
                            total += CalculateFromImage(img);
                        }
                    }
                }
            }
        }

        return total;
    }

    /// <summary>
    /// Calcualte token for image input.
    /// https://platform.openai.com/docs/guides/vision/calculating-costs
    /// </summary>
    /// <param name="img"></param>
    /// <returns></returns>
    private int CalculateFromImage(Image img)
    {
        if (Math.Max(img.Width, img.Height) < 512)
        {
            return 85;
        }
        else if (Math.Max(img.Width, img.Height) < 2048)
        {
            if (Math.Min(img.Width, img.Height) > 768)
            {
                int largeSide = (int)Math.Ceiling(
                    (double)768 /
                    Math.Min(img.Width, img.Height) *
                    Math.Max(img.Width, img.Height) /
                    512);
                return largeSide * 2 * 170 + 85;
            }
            else
            {
                int largeSide = (int)Math.Ceiling(
                    (double)(Math.Max(img.Width, img.Height) /
                    512));
                return largeSide * 2 * 170 + 85;
            }
        }
        else
        {
            int largeSide = (int)Math.Ceiling(
                (double)768 / 
                (Math.Min(img.Width, img.Height) / (Math.Max(img.Width, img.Height) / 2048)) *
                2048 / 
                512);
            return largeSide * 2 * 170 + 85;
        }
    }

    /// <summary>
    /// Count the number of tokens for the input
    /// </summary>
    /// <param name="input">TikTokenService</param>
    /// <returns>Token count</returns>
    public int CountToken(string input)
    {
        return tikToken.Encode(input).Count;
    }
}
