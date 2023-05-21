// exercise 2
package main
import (
    "crypto/rand"
    "fmt"
    "os"
)
// Shred function can be used to securely delete sensitive files
// that contain confidential or private information, such as
// finantial records, personal documents, sensitive data etc.
// Shred function provides an additional layer of security by
// simply overwriting the file's data with random information
// Overwriting large files multiple times with random data
// can be time consuming. This can lead to increased wear on
//  certain storage media types such as SSDs. Once shreded,
// recovering original file content is almost impossible.
func Shred(path string) error {
    // Open the file with read/write flag
    file, err := os.OpenFile(path, os.O_RDWR, 0666)
    if err != nil {
        return err
    }
    defer file.Close()
    // Get the file size
    fileInfo, err := file.Stat()
    if err != nil {
        return err
    }
    fileSize := fileInfo.Size()
    // Overwrite the file three times with random data
    for i := 0; i < 3; i++ {
        // Generate random data
        randomData := make([]byte, fileSize)
        _, err := rand.Read(randomData)
        if err != nil {
            return err
        }
        // Seek to the beginning of the file
        _, err = file.Seek(0, 0)
        if err != nil {
            return err
        }
        // Write random data to the file
        // alternatively one may write 1 byte at a time in for loop
        _, err = file.Write(randomData)
        if err != nil {
            return err
        }
        // Sync changes to disk
        err = file.Sync()
        if err != nil {
            return err
        }
    }
    // Close the file
    err = file.Close()
    if err != nil {
        return err
    }
    // Delete the file
    err = os.Remove(path)
    if err != nil {
        return err
    }
    fmt.Printf("File %s has been shredded.\n", path)
    return nil
}
func main() {
    filePath := "path/file.txt" // example file path
    err := Shred(filePath)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
}
